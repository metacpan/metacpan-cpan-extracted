package DBIO::PostgreSQL::Deploy;
# ABSTRACT: Deploy and upgrade PostgreSQL schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use DBIO::PostgreSQL::DDL       ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Diff      ();
use DBIO::SQL::Util qw(_quote_ident);


# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class       { 'DBIO::PostgreSQL::DDL'       }
sub _introspect_class { 'DBIO::PostgreSQL::Introspect' }
sub _diff_class      { 'DBIO::PostgreSQL::Diff'      }


sub install_schema {
  my ($self, $schema_name) = @_;
  my $dbh = $self->_dbh;
  $dbh->do(sprintf 'CREATE SCHEMA IF NOT EXISTS %s', _quote_ident($schema_name));
  return 1;
}

# --- PostgreSQL-specific overrides -----------------------------------------


sub _new_introspect {
  my ($self, $dbh) = @_;
  my @schemas = $self->schema->pg_schemas;
  my $filter  = @schemas ? \@schemas : undef;
  return $self->_introspect_class->new(
    dbh           => $dbh,
    schema_filter => $filter,
  );
}


sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do("COMMIT") if $dbh->{AutoCommit} == 0;
  local $dbh->{AutoCommit} = 1;
  $dbh->do(sprintf 'CREATE DATABASE %s', _quote_ident($name));
  return $name;
}


sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $dbh->do("COMMIT") if $dbh->{AutoCommit} == 0;
  local $dbh->{AutoCommit} = 1;
  $dbh->do(sprintf 'DROP DATABASE IF EXISTS %s', _quote_ident($name));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Deploy - Deploy and upgrade PostgreSQL schemas via test-deploy-and-compare

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Deploy> orchestrates the deployment and upgrade of
PostgreSQL schemas using a test-deploy-and-compare strategy. The shared
orchestration (L<install|/install>, L<diff|/diff>, L<apply|/apply>,
L<upgrade|/upgrade>) and the temporary-database dance are inherited from
L<DBIO::Deploy::Base::TempDatabase>; this class supplies only the genuinely
PostgreSQL-specific seams (the C<CREATE DATABASE> / C<DROP DATABASE>
dialect and the C<schema_filter> passed to the introspector).

For upgrades, the strategy is:

=over 4

=item 1. Introspect the live database via C<pg_catalog>

=item 2. Create a temporary database

=item 3. Deploy the desired schema (from DBIO classes) into the temp database

=item 4. Introspect the temp database via C<pg_catalog>

=item 5. Compute the diff between the two models using L<DBIO::PostgreSQL::Diff>

=item 6. Drop the temp database

=back

This means PostgreSQL is comparing with itself — the diff is always accurate
regardless of how complex the schema features are.

    my $deploy = DBIO::PostgreSQL::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );

    # Fresh install
    $deploy->install;

    # Upgrade (test-deploy + compare + apply)
    $deploy->upgrade;

    # Or in steps:
    my $diff = $deploy->diff;
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

=head1 METHODS

=head2 install_schema

    $deploy->install_schema('tenant_42');

Creates a single PostgreSQL schema (namespace) using C<CREATE SCHEMA IF NOT
EXISTS>. Useful for multi-tenant setups where each tenant gets its own
schema.

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

Factory for the introspector. Override in a subclass to use a custom
L<DBIO::PostgreSQL::Introspect> subclass (e.g. L<DBIO::PostgreSQL::PostGIS::Introspect>).

The base class only passes C<dbh>; here we also forward the C<schema_filter>
derived from the connected schema's C<pg_schemas> so introspection stays
scoped to the schemas this driver manages.

=head2 _create_temp_db

    my $name = $self->_create_temp_db($dbh);

PostgreSQL C<CREATE DATABASE> cannot run inside a transaction block, so the
dbh is forced into autocommit mode for the duration. Returns the new database
name (C<< temp_db_prefix . $$ . '_' . time() >>).

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drops the temporary database. Forcibly commits any open transaction first
(symmetric to L</_create_temp_db>).

=over 4

=item * L<DBIO::PostgreSQL> - schema component with C<pg_deploy> factory method

=item * L<DBIO::PostgreSQL::DDL> - generates the DDL used by C<install> and C<diff>

=item * L<DBIO::PostgreSQL::Introspect> - reads the live and temp database state

=item * L<DBIO::PostgreSQL::Diff> - compares the two introspected models

=item * L<DBIO::Deploy::Base::TempDatabase> - inherited orchestration

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
