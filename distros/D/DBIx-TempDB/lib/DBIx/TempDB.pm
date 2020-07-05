package DBIx::TempDB;
use strict;
use warnings;

use Carp qw(confess croak);
use Cwd ();
use DBI;
use DBIx::TempDB::Util qw(dsn_for on_process_end parse_sql);
use File::Basename ();
use File::Spec;
use IO::Handle ();
use Scalar::Util 'blessed';
use Sys::Hostname ();
use URI::db;

use constant CWD                 => eval { File::Basename::dirname(Cwd::abs_path($0)) };
use constant DEBUG               => $ENV{DBIX_TEMP_DB_DEBUG} || 0;
use constant MAX_NUMBER_OF_TRIES => $ENV{DBIX_TEMP_DB_MAX_NUMBER_OF_TRIES} || 20;

our $VERSION = '0.16';
our %SCHEMA_DATABASE = (pg => 'postgres', mysql => 'mysql', sqlite => '');
my $N = 0;

sub create_database {
  my $self = shift;
  return $self if $self->{created};

  local $@;
  my $mode = !$self->{drop_from_child} ? 'destroy' : $self->{drop_from_child} == 2 ? 'double_fork' : 'fork';
  my ($guard, $name) = 0;
  while (++$guard < MAX_NUMBER_OF_TRIES) {
    $name = $self->_generate_database_name($N + $guard - 1);
    eval { $self->_create_database($name) } or next;
    $self->{database_name} = $name;
    warn "[TempDB:$$] Created @{[$ENV{DBIX_TEMP_DB_KEEP_DATABASE} ? 'permanent' : 'temp']} database $name\n" if DEBUG;
    $self->{guard} = on_process_end $mode => $self->_drop_database_cb($self->{database_name})
      unless $ENV{DBIX_TEMP_DB_KEEP_DATABASE};
    $self->{created}++;
    $self->{url}->dbname($name);
    $ENV{DBIX_TEMP_DB_URL} = $self->{url}->uri->as_string;
    $N++;
    return $self;
  }

  croak qq(Couldn't create database "$name": $@);
}

sub drop_databases {
  my ($self, $params) = @_;

  my $self_db_name = $self->{database_name} || '';
  my $delete_self  = $params->{self}        || '';
  delete $self->{guard} if $delete_self;

  # Drop a single database by name
  return $self->_drop_database($params->{name}) if $params->{name};
  return $self->_drop_database($self_db_name)   if $delete_self eq 'only';

  # Drop sibling (and curren) databases
  my $max = $N > MAX_NUMBER_OF_TRIES ? $N : MAX_NUMBER_OF_TRIES;
  my @err;
  for my $n (0 .. $max) {
    my $name = $self->_generate_database_name($n);
    next unless $delete_self eq 'include' or ($self_db_name and $self_db_name ne $name);
    push @err, $@ unless eval { $self->_drop_database($name); 1 };
  }

  croak $err[0] if @err == $max;
  return $self;
}

sub dsn {
  my ($self, $url) = @_;

  unless (blessed $self) {
    Carp::carp("DBIx::TempDB->dsn(...) is deprecated. Use DBIx::TempDB::Util::dsn_for() instead");
    $url = URI::db->new($url) unless blessed $url;
    return dsn_for($url, $url->dbname);
  }

  croak "Can't call dsn() before create_database()" unless $self->{database_name};
  croak 'Database does not exist.' if $self->url->canonical_engine eq 'sqlite' and !-e $self->{database_name};
  return dsn_for($self->{url}, $self->{database_name});
}

sub execute {
  my $self = shift;
  my $dbh  = DBI->connect($self->dsn);
  local $dbh->{sqlite_allow_multiple_statements} = 1 if $self->url->canonical_engine eq 'sqlite';
  $dbh->do($_) for map { parse_sql($self->url, $_) } @_;
  return $self;
}

sub execute_file {
  my ($self, $path) = @_;

  unless (File::Spec->file_name_is_absolute($path)) {
    croak qq(Can't resolve path to "$path".) unless CWD;
    $path = File::Spec->catfile(CWD, split '/', $path);
  }

  open my $SQL, '<', $path or croak "Can't open $path: $!";
  my $ret = my $sql = '';
  while ($ret = $SQL->sysread(my $buffer, 131072, 0)) { $sql .= $buffer }
  croak qq{Can't read "$path": $!} unless defined $ret;
  warn "[TempDB:$$] Execute $path\n" if DEBUG;
  return $self->execute($sql);
}

sub new {
  my $class = shift;
  my $url   = URI::db->new(shift || '');
  my $self  = bless {@_, url => $url}, $class;

  $self->{drop_from_child} //= 1;
  $self->{schema_database} ||= $SCHEMA_DATABASE{$url->canonical_engine} // croak qq(Unsupported engine for $url);
  $self->{template}        ||= 'tmp_%U_%X_%H%i';
  warn "[TempDB:$$] schema_database=$self->{schema_database}\n" if DEBUG;

  return $self->create_database if $self->{auto_create} // 1;
  return $self;
}

sub url { shift->{url}->uri }

sub _create_database {
  my ($self, $name) = @_;

  if ($self->url->canonical_engine eq 'sqlite') {
    require IO::File;
    use Fcntl qw(O_CREAT O_EXCL O_RDWR);
    IO::File->new->open($name, O_CREAT | O_EXCL | O_RDWR) or confess "Can't write $name: $!\n";
  }
  else {
    DBI->connect($self->_schema_dsn)->do(sprintf 'create database %s', $name);
  }
}

sub _drop_database { shift->_drop_database_cb(shift)->() }

sub _drop_database_cb {
  my ($self, $name) = @_;

  if ($self->url->canonical_engine eq 'sqlite') {
    return sub {
      local $! = 0;
      unlink $name                                     if -e $name;
      confess "[TempDB:$$] Can't unlink $name: $!"     if $! and $! != 2;
      warn "[TempDB:$$] Dropped temp database $name\n" if DEBUG;
    };
  }

  my $sql = sprintf 'drop database if exists %s', $name;
  $sql =~ s!\%d!$name!g;
  return sub {
    my $dbh = DBI->connect($self->_schema_dsn);
    eval { $dbh->do('set client_min_messages to warning') };    # for postgres
    $dbh->do($sql);
    warn "[TempDB:$$] Dropped temp database $name\n" if DEBUG;
  };
}

sub _generate_database_name {
  my ($self, $n) = @_;
  my $name = $self->{template};

  $name =~ s/\%([iHPTUX])/{
      $1 eq 'i' ? ($n > 0 ? "_$n" : '')
    : $1 eq 'H' ? Sys::Hostname::hostname()
    : $1 eq 'P' ? $$
    : $1 eq 'T' ? $^T
    : $1 eq 'U' ? $<
    : $1 eq 'X' ? File::Basename::basename($0)
    :             "\%$1"
  }/egx;

  if (63 < length $name and !$self->{keep_too_long_database_name}) {
    confess qq(Can't create a shorter database name with "$self->{template}".)
      unless $self->{template} =~ s!\%T!!g
      or $self->{template}     =~ s!\%H!!g
      or $self->{template}     =~ s!\%X!!g;
    return $self->_generate_database_name($n);
  }

  $name =~ s!^/+!!;
  $name =~ s!\W!_!g;
  $name = lc $name;

  return $name if $self->url->canonical_engine ne 'sqlite';
  return File::Spec->catfile($self->_tempdir, "$name.sqlite");
}

sub _schema_dsn {
  my $self = shift;
  local $self->{database_name} = $self->{schema_database};
  return $self->dsn;
}

sub _tempdir {
  shift->{tempdir} ||= File::Spec->tmpdir;
}

1;

=encoding utf8

=head1 NAME

DBIx::TempDB - Create a temporary database

=head1 VERSION

0.16

=head1 SYNOPSIS

  use Test::More;
  use DBIx::TempDB;
  use DBI;

  # provide credentials with environment variables
  plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

  # create a temp database
  my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN});

  # print complete url to db server with database name
  diag $tmpdb->url;

  # useful for reading in fixtures
  $tmpdb->execute("create table users (name text)");
  $tmpdb->execute_file("path/to/file.sql");

  # connect to the temp database
  my $db = DBI->connect($tmpdb->dsn);

  # run tests...

  done_testing;
  # database is cleaned up when test exit

=head1 DESCRIPTION

L<DBIx::TempDB> is a module which allows you to create a temporary database,
which only lives as long as your process is alive. This can be very
convenient when you want to run tests in parallel, without messing up the
state between tests.

This module currently support PostgreSQL, MySQL and SQLite by installing the optional
L<DBD::Pg>, L<DBD::mysql> and/or L<DBD::SQLite> modules.

Please create an L<issue|https://github.com/jhthorsen/dbix-tempdb/issues>
or pull request for more backend support.

=head1 CAVEAT

Creating a database is easy, but making sure it gets clean up when your
process exit is a totally different ball game. This means that
L<DBIx::TempDB> might fill up your server with random databases, unless
you choose the right "drop strategy". Have a look at the L</drop_from_child>
parameter you can give to L</new> and test the different values and select
the one that works for you.

=head1 ENVIRONMENT VARIABLES

=head2 DBIX_TEMP_DB_KEEP_DATABASE

Setting this variable will disable the core feature in this module:
A unique database will be created, but it will not get dropped/deleted.

=head2 DBIX_TEMP_DB_URL

This variable is set by L</create_database> and contains the complete
URL pointing to the temporary database.

Note that calling L</create_database> on different instances of
L<DBIx::TempDB> will overwrite C<DBIX_TEMP_DB_URL>.

=head1 METHODS

=head2 create_database

  $tmpdb = $tmpdb->create_database;

This method will create a temp database for the current process. Calling this
method multiple times will simply do nothing. This method is normally
automatically called by L</new>.

The database name generate is defined by the L</template> parameter passed to
L</new>, but normalization will be done to make it work for the given database.

=head2 drop_databases

  $tmpdb->drop_databases;
  $tmpdb->drop_databases({tmpdb => "include"});
  $tmpdb->drop_databases({tmpdb => "only"});
  $tmpdb->drop_databases({name => "some_database_name"});

Used to drop either sibling databases (default), sibling databases and the
current database or a given database by name.

=head2 dsn

  ($dsn, $user, $pass, $attrs) = $tmpdb->dsn;

Will parse L</url> and return a list of arguments suitable for L<DBI/connect>.

Note that this method cannot be called as an object method before
L</create_database> is called.

See also L<DBIx::TempDB::Util/dsn_for>.

=head2 execute

  $tmpdb = $tmpdb->execute(@sql);

This method will execute a list of C<@sql> statements in the temporary
SQL server.

=head2 execute_file

  $tmpdb = $tmpdb->execute_file("relative/to/executable.sql");
  $tmpdb = $tmpdb->execute_file("/absolute/path/stmt.sql");

This method will read the contents of a file and execute the SQL statements
in the temporary server.

This method is a thin wrapper around L</execute>.

=head2 new

  $tmpdb = DBIx::TempDB->new($url, %args);
  $tmpdb = DBIx::TempDB->new("mysql://127.0.0.1");
  $tmpdb = DBIx::TempDB->new("postgresql://postgres@db.example.com");
  $tmpdb = DBIx::TempDB->new("sqlite:");

Creates a new object after checking the C<$url> is valid. C<%args> can be:

=over 4

=item * auto_create

L</create_database> will be called automatically, unless C<auto_create> is
set to a false value.

=item * drop_from_child

Setting "drop_from_child" to a true value will create a child process which
will remove the temporary database, when the main process ends. There are two
possible values:

C<drop_from_child=1> (the default) will create a child process which monitor
the L<DBIx::TempDB> object with a pipe. This will then DROP the temp database
if the object goes out of scope or if the process ends.

C<drop_from_child=2> will create a child process detached from the parent,
which monitor the parent with C<kill(0, $parent)>.

The double fork code is based on a paste contributed by
L<Easy Connect AS|http://easyconnect.no>, Knut Arne Bjørndal.

See also L<DBIx::TempDB::Util/on_process_end>.

=item * template

Customize the generated database name. Default template is "tmp_%U_%X_%H%i".
Possible variables to expand are:

  %i = The number of tries if tries are higher than 0. Example: "_3"
  %H = Hostname
  %P = Process ID ($$)
  %T = Process start time ($^T)
  %U = UID of current user
  %X = Basename of executable

The default is subject to change!

=back

=head2 url

  $url = $tmpdb->url;

Returns the input URL as L<URI::db> compatible object. This URL will have
the L<dbname|URI::db/dbname> part set to the database from L</create_database>,
but not I<until> after L</create_database> is actually called.

The URL returned can be passed directly to modules such as L<Mojo::Pg>
and L<Mojo::mysql>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
