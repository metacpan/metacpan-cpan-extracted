package DBIO::DuckDB::Test;
# ABSTRACT: DuckDB-specific test utilities for DBIO

use strict;
use warnings;

use DBIO::Test;
use DBIO::Test::Schema;
use Carp;


sub import {
  my $self = shift;
  if (@_) {
    my $caller = caller;
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
        # no-op, parallel to DBIO::SQLite::Test
      }
      else {
        croak "Unknown export $exp requested from $self";
      }
    }
  }
}


sub _database {
  my $self = shift;
  my %args = @_;

  if ($ENV{DBIO_TEST_DUCKDB_DSN}) {
    return (
      (map { $ENV{"DBIO_TEST_DUCKDB_${_}"} // '' } qw/DSN DBUSER DBPASS/),
      { AutoCommit => 1, RaiseError => 1, PrintError => 0, %args },
    );
  }

  return (
    'dbi:DuckDB:dbname=:memory:',
    '', '',
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, %args },
  );
}


sub init_schema {
  my $self = shift;
  my %args = @_;

  my ($dsn, $user, $pass, $opts) = $self->_database(%args);

  return DBIO::Test->init_schema(
    dsn          => $dsn,
    user         => $user,
    pass         => $pass,
    connect_opts => $opts,
    storage_type => '+DBIO::DuckDB::Storage',
    %args,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Test - DuckDB-specific test utilities for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  use DBIO::DuckDB::Test;

  my $schema = DBIO::DuckDB::Test->init_schema;
  my $rs = $schema->resultset('Artist');

=head1 DESCRIPTION

Extends L<DBIO::Test> with DuckDB-specific test helpers for the
L<DBIO::DuckDB> driver distribution. Mirrors L<DBIO::SQLite::Test>:
driver tests call C<< DBIO::DuckDB::Test->init_schema >> and get a
connected, deployed schema backed by an in-memory DuckDB.

=head1 METHODS

=head2 _database

Returns C<($dsn, $user, $pass, \%opts)> for C<< $schema->connect() >>.
Honours C<DBIO_TEST_DUCKDB_DSN> if set, otherwise uses
C<dbi:DuckDB:dbname=:memory:>.

=head2 init_schema

  my $schema = DBIO::DuckDB::Test->init_schema(%opts);

Thin wrapper around L<DBIO::Test/init_schema>. Fills in C<dsn> and
C<storage_type> for DuckDB (honouring C<DBIO_TEST_DUCKDB_DSN>) and then
delegates to the core harness.

Core's C<deploy_schema> calls C<< $schema->deploy >>, which
L<DBIO::Schema/deploy> routes through C<dbio_deploy_class> when set on
the storage class -- so DuckDB deployment goes through
L<DBIO::DuckDB::Deploy> (the native test-and-compare path), not
SQL::Translator. No extra install step needed here.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
