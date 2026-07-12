package DBIO::DuckDB::Deploy;
# ABSTRACT: Deploy and upgrade DuckDB schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Introspect;
use DBIO::DuckDB::Diff;


sub catalog { $_[0]->{catalog} }

sub _ddl_class        { 'DBIO::DuckDB::DDL' }
sub _introspect_class { 'DBIO::DuckDB::Introspect' }
sub _diff_class       { 'DBIO::DuckDB::Diff' }




sub _new_introspect {
  my ($self, $dbh) = @_;
  my %opts = (dbh => $dbh);
  $opts{catalog} = $self->catalog if defined $self->catalog;
  return $self->_introspect_class->new(%opts);
}


sub _build_target_model {
  my ($self) = @_;

  my $temp_dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });

  $self->_execute_ddl($temp_dbh, $self->_install_ddl);

  my $target_model = $self->_introspect_class->new(dbh => $temp_dbh)->model;
  $temp_dbh->disconnect;

  return $target_model;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Deploy - Deploy and upgrade DuckDB schemas via test-deploy-and-compare

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::DuckDB::Deploy> orchestrates schema deployment and upgrades for
DuckDB using the test-deploy-and-compare strategy, parallel to
L<DBIO::SQLite::Deploy> and L<DBIO::PostgreSQL::Deploy>.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<information_schema> / C<duckdb_*>

=item 2. Connects to a fresh in-memory DuckDB database

=item 3. Deploys the desired schema (from DBIO classes) into that in-memory DB

=item 4. Introspects the in-memory database the same way

=item 5. Computes the diff between the two models using L<DBIO::DuckDB::Diff>

=back

DuckDB supports C<:memory:> so the throwaway DB is as cheap as with
SQLite -- no CREATE DATABASE dance like PostgreSQL.

    my $deploy = DBIO::DuckDB::Deploy->new(
        schema => MyApp::DB->connect("dbi:DuckDB:dbname=app.duckdb"),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the L<DBIO::DuckDB> component.
Required.

=head2 catalog

Optional catalog name (e.g. a locally-attached file database). When set,
the source introspection is scoped to this catalog. Useful for multi-catalog
deployments and DuckLake.

B<Not applicable for Quack RPC remotes.> The remote catalog is opaque to
C<information_schema> -- deploy the schema on the B<server> process instead,
not against the client-side quack attach. Use C<PRAGMA table_info('remote.t')>
on the client to verify remote columns.

=head1 METHODS

=head2 install

    $deploy->install;

Generates DDL via L<DBIO::DuckDB::DDL/install_ddl> and executes each
statement against the connected database. Suitable for fresh installs.
Inherited from L<DBIO::Deploy::Base>.

=head2 diff

    my $diff = $deploy->diff;

Computes the difference between the live database and the desired state.
Spins up a throwaway in-memory DuckDB, deploys the desired schema there,
introspects both, and returns a L<DBIO::DuckDB::Diff> object. The
orchestration is inherited from L<DBIO::Deploy::Base>; only the
in-memory target build (L</_build_target_model>) and the catalog-aware
source introspection (L</_new_introspect>) are DuckDB-specific.

=head2 apply

    $deploy->apply($diff);

Applies a L<DBIO::DuckDB::Diff> object by executing each statement from
C<< $diff->as_sql >>. No-op if the diff has no changes. Inherited from
L<DBIO::Deploy::Base>.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: calls L</diff> then L</apply>. Returns the diff object if
changes were applied, or C<undef> if the database was already up to date.
Inherited from L<DBIO::Deploy::Base>.

=head2 _new_introspect

Factory for the source-side introspector. Overrides
L<DBIO::Deploy::Base/_new_introspect> to forward the C<catalog> attribute
(for locally-attached file / DuckLake catalogs) when it is set.

=head2 _build_target_model

Builds the desired-state model: connects a throwaway in-memory DuckDB,
deploys the install DDL there, and introspects it. DuckDB supports
C<:memory:>, so this is as cheap as with SQLite -- no temporary-database
dance like PostgreSQL. The temp DB is never scoped to C<catalog>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::DuckDB> - schema component

=item * L<DBIO::DuckDB::DDL> - generates DDL

=item * L<DBIO::DuckDB::Introspect> - reads live database state

=item * L<DBIO::DuckDB::Diff> - compares two introspected models

=item * L<DBIO::SQLite::Deploy> - sibling implementation

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
