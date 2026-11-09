package DBIO::SQLite::Test;
# ABSTRACT: SQLite-specific test utilities for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Test;
use DBIO::Test::Schema;
use Carp;
use DBIO::Util qw(dir_path parent_dir mkpath);


sub import {
  my $self = shift;

  # Delegate :DiffSQL and other exports to DBIO::Test
  if (@_) {
    my $caller = caller;
    # Manually re-export into caller's namespace
    for my $exp (@_) {
      if ($exp eq ':DiffSQL') {
        require DBIO::SQLMaker;
        require SQL::Abstract::Test;
        for (qw(is_same_sql_bind is_same_sql is_same_bind)) {
          no strict 'refs';
          *{"${caller}::$_"} = \&{"SQL::Abstract::Test::$_"};
        }
      }
      elsif ($exp eq ':GlobalLock') {
        # GlobalLock is a no-op in the DBIO test suite — the original
        # DBIOTest locking mechanism is not needed outside of the old
        # concurrent test infrastructure.
      }
      else {
        croak "Unknown export $exp requested from $self";
      }
    }
  }
}

{
  my $dir;
  sub _vardir {
    return $dir if $dir;
    $dir = dir_path(
      parent_dir(parent_dir(parent_dir(parent_dir(__FILE__)))),
      't', 'var',
    );
    mkpath($dir) unless -d $dir;
    return $dir;
  }
}


sub _sqlite_dbfilename {
  my $self = shift;
  my $holder = $ENV{DBIO_TEST_LOCK_HOLDER} || $$;
  $holder = $$ if $holder == -1;
  return _vardir() . "/DBIOTest-$holder.db";
}


sub _sqlite_dbname {
  my $self = shift;
  my %args = @_;
  return $self->_sqlite_dbfilename if (
    defined $args{sqlite_use_file} ? $args{sqlite_use_file} : $ENV{'DBIO_TEST_SQLITE_USE_FILE'}
  );
  return ":memory:";
}


# Arguments of init_schema that steer the helper itself. They are not
# connect attributes and must never reach connect(): the storage rejects a
# connect attribute it does not know (karr k76).
my @HELPER_ARGS = qw(
  dsn connect_info user pass connect_opts
  no_deploy no_populate no_connect deploy_args
  storage_type replicated replicant_connect_info compose_connection
  sqlite_use_file
);

sub _database {
  my $self = shift;
  my %args = @_;

  my %connect_attrs = %args;
  delete @connect_attrs{@HELPER_ARGS};

  if ($ENV{DBIO_TEST_DSN}) {
    return (
      (map { $ENV{"DBIO_TEST_${_}"} // '' } qw/DSN DBUSER DBPASS/),
      { AutoCommit => 1, %connect_attrs },
    );
  }

  my $db_file = $self->_sqlite_dbname(%args);

  for ($db_file, "${db_file}-journal") {
    next unless -e $_;
    unlink ($_) or carp (
      "Unable to unlink existing test database file $_ ($!), "
      . "creation of fresh database / further tests may fail!"
    );
  }

  return ("dbi:SQLite:${db_file}", '', '', {
    AutoCommit => 1,
    on_connect_do => sub {
      my $storage = shift;
      my $dbh = $storage->_get_dbh;
      $dbh->do('PRAGMA synchronous = OFF');

      if (
        $ENV{DBIO_TEST_SQLITE_REVERSE_DEFAULT_ORDER}
          and
        $storage->_server_info->{normalized_dbms_version} >= 3.007009
      ) {
        $dbh->do('PRAGMA reverse_unordered_selects = ON');
      }
    },
    %connect_attrs,
  });
}


sub init_schema {
  my $self = shift;
  my %args = @_;

  # A schema always has a driver (core ADR 0067), and DBIO::Test::Schema
  # keeps none in its class: this helper declares SQLite unless the caller
  # names a storage_type. Set before the normalization, so that
  # replicated => 1 runs its backends on it as well.
  $args{storage_type} //= 'DBIO::SQLite::Storage';
  %args = %{ DBIO::Test->normalize_init_schema_args(\%args) };
  $args{storage_type} = $self->_backend_storage_class($args{storage_type});

  my $schema;

  if ($args{compose_connection}) {
    $schema = DBIO::Test::Schema->compose_connection(
      'DBIO::Test', $self->_database(%args)
    );
  } else {
    $schema = DBIO::Test::Schema->compose_namespace('DBIO::Test');
  }

  if ($args{storage_type}) {
    $schema->storage_type($args{storage_type});
  }

  if (!$args{no_connect}) {
    $schema = $schema->connect($self->_database(%args));

    if ($args{replicant_connect_info} && $schema->storage->isa('DBIO::Replicated::Storage')) {
      $schema->storage->connect_replicants(@{ $args{replicant_connect_info} });
    }
  }

  if (!$args{no_deploy}) {
    DBIO::Test->deploy_schema($schema, $args{deploy_args});
    DBIO::Test->populate_schema($schema)
      unless $args{no_populate};
  }

  return $schema;
}

# normalize_init_schema_args records the driver of replicated => 1 as
# backend_storage_type; DBIO::Replicated::Storage builds its master and
# replicants from backend_storage_class. Hand the driver on under that name,
# unless the caller gave backend_storage_class itself. Any other storage_type
# is returned as given.
sub _backend_storage_class {
  my ($self, $storage_type) = @_;

  return $storage_type unless ref $storage_type eq 'HASH';

  my ($storage_class, $args) = %$storage_type;
  (my $plain = $storage_class) =~ s/^\+//;
  return $storage_type unless $plain eq 'DBIO::Replicated::Storage';

  my %replicated_args = %{ $args || {} };
  my $backend = delete $replicated_args{backend_storage_type};
  $replicated_args{backend_storage_class} //= $backend if defined $backend;

  return { $storage_class => \%replicated_args };
}

sub _cleanup_dbfile {
  my $self = shift;
  if (
    ! $ENV{DBIO_TEST_LOCK_HOLDER}
      or
    $ENV{DBIO_TEST_LOCK_HOLDER} == -1
      or
    $ENV{DBIO_TEST_LOCK_HOLDER} == $$
  ) {
    my $db_file = $self->_sqlite_dbfilename;
    unlink $_ for ($db_file, "${db_file}-journal");
  }
}

END {
  __PACKAGE__->_cleanup_dbfile;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Test - SQLite-specific test utilities for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::SQLite::Test;

  # In-memory schema (most tests)
  my $schema = DBIO::SQLite::Test->init_schema;

  # File-based schema (for reconnect/persistence tests)
  my $schema = DBIO::SQLite::Test->init_schema(sqlite_use_file => 1);

  # Shared driver test through replicated storage
  my $replicated = DBIO::SQLite::Test->init_schema(
    replicated   => 1,
    storage_type => 'DBIO::SQLite::Storage',
  );

=head1 DESCRIPTION

Extends L<DBIO::Test> with SQLite-specific test helpers for the
L<DBIO::SQLite> driver distribution.

=head1 METHODS

=head2 _sqlite_dbfilename

Returns the path to the file-based test SQLite database.

=head2 _sqlite_dbname

Returns the database name — either a file path or C<:memory:>.

=head2 _database

Returns a list of C<($dsn, $user, $pass, \%opts)> suitable for
C<< $schema->connect() >>.

The arguments are those of L</init_schema>. The ones that steer the helper
itself (C<no_deploy>, C<no_populate>, C<storage_type>, C<sqlite_use_file>,
...) are consumed here and left out of the connect attributes; everything
else (C<quote_names>, C<auto_savepoint>, C<on_connect_do>, C<AutoCommit>,
DBI attributes) is passed on to the connection.

=head2 init_schema

  my $schema = DBIO::SQLite::Test->init_schema(%opts);

Wrapper around L<DBIO::Test/init_schema> that defaults to an
in-memory SQLite database.

Supports all L<DBIO::Test/init_schema> options plus:

=over 4

=item sqlite_use_file

Use a file-based SQLite database instead of C<:memory:>.

=back

The schema declares L<DBIO::SQLite::Storage> as its driver unless
C<storage_type> names another storage class: a schema always has a driver
(core ADR 0067), and L<DBIO::Test::Schema> keeps none in its class.

Shared L<DBIO::Test> options such as C<replicated =E<gt> 1> are normalized
before the SQLite-specific connection is built, so driver tests can opt
into replicated coverage without rebuilding their schema setup. The master
and every replicant are storages of the declared driver: the helper passes
it on as C<backend_storage_class>, unless a full replicated C<storage_type>
gives one itself.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
