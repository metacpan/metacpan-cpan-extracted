package DBIx::TempDB;
use strict;
use warnings;
use Carp 'confess';
use Cwd ();
use DBI;
use File::Basename ();
use File::Spec;
use IO::Handle    ();
use Sys::Hostname ();
use URI::db;
use URI::QueryParam;

use constant CWD => eval { File::Basename::dirname(Cwd::abs_path($0)) };
use constant DEBUG               => $ENV{DBIX_TEMP_DB_DEBUG}               || 0;
use constant KILL_SLEEP_INTERVAL => $ENV{DBIX_TEMP_DB_KILL_SLEEP_INTERVAL} || 2;
use constant MAX_NUMBER_OF_TRIES => $ENV{DBIX_TEMP_DB_MAX_NUMBER_OF_TRIES} || 20;
use constant MAX_OPEN_FDS => eval { use POSIX qw(sysconf _SC_OPEN_MAX); sysconf(_SC_OPEN_MAX) } || 1024;

our $VERSION = '0.14';
our %SCHEMA_DATABASE = (pg => 'postgres', mysql => 'mysql');
my $N = 0;

sub create_database {
  return $_[0] if $_[0]->{created};
  my $self = shift;
  my ($guard, $name);

  local $@;
  while (++$guard < MAX_NUMBER_OF_TRIES) {
    $name = $self->_generate_database_name($N + $guard);
    eval { $self->_create_database($name) } or next;
    $self->{database_name} = $name;
    warn "[TempDB:$$] Created temp database $name\n" if DEBUG and !$ENV{DBIX_TEMP_DB_KEEP_DATABASE};
    warn sprintf "[DBIx::TempDB] Created permanent database %s\n", +($self->dsn)[0]
      if $ENV{DBIX_TEMP_DB_KEEP_DATABASE} and !$ENV{DBIX_TEMP_DB_SILENT};
    $self->_drop_from_child               if $self->{drop_from_child} == 1;
    $self->_drop_from_double_forked_child if $self->{drop_from_child} == 2;
    $self->{created}++;
    $self->{url}->dbname($name);
    $ENV{DBIX_TEMP_DB_URL} = $self->{url}->uri->as_string;
    $N++;
    return $self;
  }

  confess "Could not create unique database: '$name'. $@";
}

sub dsn {
  my ($self, $url) = @_;

  if (!ref $self and $url) {
    $url = URI::db->new($url) unless ref $url and $url->isa('URI::_db');
    unless ($url->has_recognized_engine) {
      confess "Scheme @{[$url->engine]} is not recognized as a database engine for connection url $url";
    }
    $self->can(sprintf '_dsn_for_%s', $url->canonical_engine)->($self, $url, $url->dbname);
  }
  else {
    confess 'Cannot return DSN before create_database() is called.' unless $self->{database_name};
    $self->can(sprintf '_dsn_for_%s', $self->url->canonical_engine)->($self, $self->url, $self->{database_name});
  }
}

sub execute {
  my $self   = shift;
  my $dbh    = DBI->connect($self->dsn);
  my $parser = $self->can("_parse_@{[$self->url->canonical_engine]}") || sub { $_[1] };
  local $dbh->{sqlite_allow_multiple_statements} = 1 if $self->url->canonical_engine eq 'sqlite';
  $dbh->do($_) for map { $self->$parser($_) } @_;
  $self;
}

sub execute_file {
  my ($self, $path) = @_;

  unless (File::Spec->file_name_is_absolute($path)) {
    confess "Cannot resolve absolute path to '$path'. Something went wrong with Cwd::abs_path($0)." unless CWD;
    $path = File::Spec->catfile(CWD, split '/', $path);
  }

  open my $SQL, '<', $path or die "DBIx::TempDB can't open $path: $!";
  my $ret = my $sql = '';
  while ($ret = $SQL->sysread(my $buffer, 131072, 0)) { $sql .= $buffer }
  die qq{DBIx::TempDB can't read from file "$path": $!} unless defined $ret;
  warn "[TempDB:$$] Execute $path\n" if DEBUG;
  $self->execute($sql);
}

sub new {
  my $class = shift;
  my $url = URI::db->new(shift || '');
  unless ($url->has_recognized_engine) {
    confess "Scheme @{[$url->engine]} is not recognized as a database engine for connection url $url";
  }
  my $self = bless {@_, url => $url}, $class;
  my $dsn_for = sprintf '_dsn_for_%s', $url->canonical_engine || '';

  unless ($self->can($dsn_for)) {
    confess "Cannot generate temp database for '@{[$url->canonical_engine]}'. $class\::$dsn_for() is missing";
  }

  $self->{create_database_command} ||= 'create database %d';
  $self->{drop_database_command}   ||= 'drop database %d';
  $self->{drop_from_child} //= 1;
  $self->{schema_database} ||= $SCHEMA_DATABASE{$url->canonical_engine};
  $self->{template} ||= 'tmp_%U_%X_%H%i';
  warn "[TempDB:$$] schema_database=$self->{schema_database}\n" if DEBUG;

  $self->{drop_from_child} = 0 if $ENV{DBIX_TEMP_DB_KEEP_DATABASE};

  return $self->create_database if $self->{auto_create} // 1;
  return $self;
}

sub url { shift->{url}->uri }

sub DESTROY {
  my $self = shift;
  return close $self->{DROP_PIPE} if $self->{DROP_PIPE};
  return                          if $ENV{DBIX_TEMP_DB_KEEP_DATABASE};
  return                          if $self->{double_forked};
  return $self->_cleanup          if $self->{created};
}

sub _cleanup {
  my $self = shift;

  eval {
    if (ref $self->{drop_database_command} eq 'CODE') {
      $self->{drop_database_command}->($self, $self->{database_name});
    }
    elsif ($self->url->canonical_engine eq 'sqlite') {
      unlink $self->{database_name} or die $!;
    }
    else {
      my $sql = $self->{drop_database_command};
      $sql =~ s!\%d!$self->{database_name}!g;
      DBI->connect($self->_schema_dsn)->do($sql);
    }
    1;
  } or do {
    die "[$$] Unable to drop $self->{database_name}: $@";
  };
}

sub _create_database {
  my ($self, $name) = @_;

  if (ref $self->{create_database_command} eq 'CODE') {
    $self->{create_database_command}->($self, $name);
  }
  elsif ($self->url->canonical_engine eq 'sqlite') {
    require IO::File;
    use Fcntl qw(O_CREAT O_EXCL O_RDWR);
    IO::File->new->open($name, O_CREAT | O_EXCL | O_RDWR) or die "open $name O_CREAT|O_EXCL|O_RDWR: $!\n";
  }
  else {
    my $sql = $self->{create_database_command};
    $sql =~ s!\%d!$name!g;
    DBI->connect($self->_schema_dsn)->do($sql);
  }
}

sub _dsn_for_pg {
  my ($class, $url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};
  my ($dsn, @userinfo);

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  if (my $service = delete $opt{service}) { $url->query_param(service => $service) }
  $dsn = $url->dbi_dsn;
  @userinfo = ($url->user, $url->password);

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;

  return $dsn, @userinfo[0, 1], \%opt;
}

sub _dsn_for_mysql {
  my ($class, $url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};
  my ($dsn, @userinfo);

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  $dsn = $url->dbi_dsn;
  @userinfo = ($url->user, $url->password);

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;
  $opt{mysql_enable_utf8}   //= 1;

  return $dsn, @userinfo[0, 1], \%opt;
}

sub _dsn_for_sqlite {
  my ($class, $url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  my $dsn = $url->dbi_dsn;

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;
  $opt{sqlite_unicode}      //= 1;

  return $dsn, "", "", \%opt;
}

sub _generate_database_name {
  my ($self, $n) = @_;
  my $name = $self->{template};

  $name =~ s/\%([iHPTUX])/{
      $1 eq 'i' ? ($n > 0 ? "_$n" : '')
    : $1 eq 'H' ? $self->_hostname
    : $1 eq 'P' ? $$
    : $1 eq 'T' ? $^T
    : $1 eq 'U' ? $<
    : $1 eq 'X' ? File::Basename::basename($0)
    :             "\%$1"
  }/egx;

  if (63 < length $name and !$self->{keep_too_long_database_name}) {
         $self->{template} =~ s!\%T!!g
      or $self->{template} =~ s!\%H!!g
      or $self->{template} =~ s!\%X!!g
      or confess "Uable to create shorter database anme.";
    warn "!!! Database name '$name' is too long! Forcing a shorter template: $self->{template}"
      if !$ENV{HARNESS_ACTIVE} or $ENV{HARNESS_VERBOSE};
    return $self->_generate_database_name($n);
  }

  $name =~ s!^/+!!;
  $name =~ s!\W!_!g;

  return $name if $self->url->canonical_engine ne 'sqlite';
  return File::Spec->catfile($self->_tempdir, "$name.sqlite");
}

sub _hostname {
  shift->{hostname} ||= Sys::Hostname::hostname();
}

sub _drop_from_child {
  my $self = shift;
  my $ppid = $$;

  pipe my $READ, $self->{DROP_PIPE} or confess "Could not create pipe: $!";
  defined(my $pid = fork) or confess "Couldn't fork: $!";

  # parent
  return $self->{drop_pid} = $pid if $pid;

  # child
  $DB::CreateTTY = 0;    # prevent debugger from creating terminals
  $SIG{$_} = sub { $self->_cleanup; exit; }
    for qw(INT QUIT TERM);

  for (0 .. MAX_OPEN_FDS - 1) {
    next if fileno($READ) == $_;
    next if DEBUG and fileno(STDERR) == $_;
    POSIX::close($_);
  }

  warn "[TempDB:$$] Waiting for $ppid to end\n" if DEBUG;
  1 while <$READ>;
  $self->_cleanup;
  exit 0;
}

sub _drop_from_double_forked_child {
  my $self = shift;
  my $ppid = $$;

  local $SIG{CHLD} = 'DEFAULT';

  defined(my $pid = fork) or confess "Couldn't fork: $!";

  if ($pid) {

    # Wait around until the second fork is done so that when we return from
    # here there are no new child processes that could mess things up if the
    # calling process does any process handling.
    waitpid $pid, 0;
    return $self->{double_forked} = $pid;    # could just be a boolean
  }

  # Stop the debugger from creating new terminals
  $DB::CreateTTY = 0;

  $0 = "drop_$self->{database_name}";

  # Detach completely from parent by creating our own session and process
  # group, closing all filehandles and forking a second time.
  POSIX::setsid() != -1 or confess "Couldn't become session leader: $!\n";
  POSIX::close($_) for 0 .. MAX_OPEN_FDS - 1;
  POSIX::_exit(0) if fork // confess "Couldn't fork: $!";
  sleep KILL_SLEEP_INTERVAL while kill 0, $ppid;
  $self->_cleanup;
  exit 0;
}

sub _parse_mysql {
  my ($self, $sql) = @_;
  my ($new, $last, $delimiter) = (0, '', ';');
  my @commands;

  while (length($sql) > 0) {
    my $token;

    if ($sql =~ /^$delimiter/x) {
      ($new, $token) = (1, $delimiter);
    }
    elsif ($sql =~ /^delimiter\s+(\S+)\s*(?:\n|\z)/ip) {
      ($new, $token, $delimiter) = (1, ${^MATCH}, $1);
    }
    elsif (
      $sql =~ /^(\s+)/s    # whitespace
      or $sql =~ /^(\w+)/
      )
    {                      # general name
      $token = $1;
    }
    elsif (
      $sql =~ /^--.*(?:\n|\z)/p                                # double-dash comment
      or $sql =~ /^\#.*(?:\n|\z)/p                             # hash comment
      or $sql =~ /^\/\*(?:[^\*]|\*[^\/])*(?:\*\/|\*\z|\z)/p    # C-style comment
      or $sql =~ /^'(?:[^'\\]*|\\(?:.|\n)|'')*(?:'|\z)/p       # single-quoted literal text
      or $sql =~ /^"(?:[^"\\]*|\\(?:.|\n)|"")*(?:"|\z)/p       # double-quoted literal text
      or $sql =~ /^`(?:[^`]*|``)*(?:`|\z)/p
      )
    {                                                          # schema-quoted literal text
      $token = ${^MATCH};
    }
    else {
      $token = substr($sql, 0, 1);
    }

    # chew token
    substr $sql, 0, length($token), '';

    if ($new) {
      push @commands, $last if $last !~ /^\s*$/s;
      ($new, $last) = (0, '');
    }
    else {
      $last .= $token;
    }
  }

  push @commands, $last if $last !~ /^\s*$/s;
  return map { s/^\s+//; $_ } @commands;
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

0.14

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

  $self = $self->create_database;

This method will create a temp database for the current process. Calling this
method multiple times will simply do nothing. This method is normally
automatically called by L</new>.

The database name generate is defined by the L</template> parameter passed to
L</new>, but normalization will be done to make it work for the given database.

=head2 dsn

  ($dsn, $user, $pass, $attrs) = $self->dsn;
  ($dsn, $user, $pass, $attrs) = DBIx::TempDB->dsn($url);

Will parse L</url> or C<$url>, and return a list of arguments suitable for
L<DBI/connect>.

Note that this method cannot be called as an object method before
L</create_database> is called. You can on the other hand call it as a class
method, with a L<URI::db> or URL string as input.

=head2 execute

  $self = $self->execute(@sql);

This method will execute a list of C<@sql> statements in the temporary
SQL server.

=head2 execute_file

  $self = $self->execute_file("relative/to/executable.sql");
  $self = $self->execute_file("/absolute/path/stmt.sql");

This method will read the contents of a file and execute the SQL statements
in the temporary server.

This method is a thin wrapper around L</execute>.

=head2 new

  $self = DBIx::TempDB->new($url, %args);
  $self = DBIx::TempDB->new("mysql://127.0.0.1");
  $self = DBIx::TempDB->new("postgresql://postgres@db.example.com");
  $self = DBIx::TempDB->new("sqlite:");

Creates a new object after checking the C<$url> is valid. C<%args> can be:

=over 4

=item * auto_create

L</create_database> will be called automatically, unless C<auto_create> is
set to a false value.

=item * create_database_command

Can be set to a custom create database command in the database. The default is
"create database %d", where %d will be replaced by the generated database name.

For even more control, you can set this to a code ref which will be called like
this:

  $self->$cb($database_name);

The default is subject to change.

=item * drop_database_command

Can be set to a custom drop database command in the database. The default is
"drop database %d", where %d will be replaced by the generated database name.

For even more control, you can set this to a code ref which will be called like
this:

  $self->$cb($database_name);

The default is subject to change.

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

  $url = $self->url;

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
