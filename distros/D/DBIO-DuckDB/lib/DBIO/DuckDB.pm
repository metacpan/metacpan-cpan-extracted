package DBIO::DuckDB;
our $VERSION = '0.900001';


# ABSTRACT: DuckDB-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::DuckDB::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB - DuckDB-specific schema management for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');

  my $schema = MyApp::Schema->connect('dbi:DuckDB:dbname=app.duckdb');

  # or, using the `-du` shortcut:
  package MyApp::Schema;
  use DBIO Schema => -du;

=head1 DESCRIPTION

L<DBIO::DuckDB> is the DuckDB driver component for DBIO. When loaded into
a schema class, C<connection()> sets L<DBIO::Schema/storage_type> to
C<+DBIO::DuckDB::Storage>, which enables DuckDB-specific storage behavior.

The driver is built on top of L<DBD::DuckDB> (which itself is a pure-FFI
DBI driver -- no XS compile, only C<libduckdb> at runtime). DuckDB is an
embedded, synchronous, columnar analytical database. This driver keeps
the DBI plumbing for all the boring ORM work (transactions, bind, cursor,
ResultSet) and exposes the interesting DuckDB-native features as direct
methods on the storage object:

=over 4

=item * L<DBIO::DuckDB::Storage/duckdb_appender> -- bulk insert via the
DuckDB Appender API

=item * L<DBIO::DuckDB::Storage/duckdb_arrow_fetch> -- columnar fetch
path (reserved for Arrow integration)

=item * L<DBIO::DuckDB::Storage/duckdb_read_csv>,
L<DBIO::DuckDB::Storage/duckdb_read_parquet>,
L<DBIO::DuckDB::Storage/duckdb_read_json> -- table-function helpers

=back

Schema management (install/diff/upgrade) uses the native
test-deploy-and-compare strategy via L<DBIO::DuckDB::Deploy>.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to force C<+DBIO::DuckDB::Storage> as
C<storage_type>.

=head1 TESTING

Tests use in-memory DuckDB databases and do not require external
credentials. The C<t/> directory contains user-level smoke scripts
(not automated TAP tests) for manually verifying the driver end-to-end
against a real libduckdb install.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
