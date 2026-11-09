package DBIO::PostgreSQL::Age::Extension;
# ABSTRACT: Apache AGE as a DBIO database extension: graph schemas are not the application's model

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';


sub extension_interface { 1 }


sub name { 'age' }


sub driver { 'DBIO::PostgreSQL' }


sub inspect {
  my ($class, $ctx) = @_;
  my $dbh = $ctx->{dbh};

  my ($have) = $dbh->selectrow_array(
    q{SELECT pg_catalog.to_regclass('ag_catalog.ag_graph')}
  );
  return { graphs => [] } unless defined $have;

  my $rows = $dbh->selectall_arrayref(
    q{SELECT g.name::text AS name, n.nspname::text AS namespace
        FROM ag_catalog.ag_graph g
        JOIN pg_catalog.pg_namespace n ON n.oid = g.namespace
       ORDER BY g.name},
    { Slice => {} },
  );

  return { graphs => [ map { { name => $_->{name}, namespace => $_->{namespace} } } @{ $rows || [] } ] };
}


sub claims {
  my ($class, $model, $ctx) = @_;
  return [ map { [ schema => $_->{namespace} ] }
    @{ ( $ctx->{self}{state} || {} )->{graphs} || [] } ];
}


sub activation { { load => 'age', search_path => ['ag_catalog'] } }


sub storage_layer { 'DBIO::PostgreSQL::Age::Storage' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Extension - Apache AGE as a DBIO database extension: graph schemas are not the application's model

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions('age');

=head1 DESCRIPTION

The extension class of Apache AGE (ADR 0066 of DBIO core). A schema that
declares C<age> in C<pg_extensions> has this class in its list of extensions;
the driver (L<DBIO::PostgreSQL>) resolves the name C<age> to it, runs it
inside deploy and registers its storage layer. Loading a component does not put
AGE on the list, and a schema that does not declare C<age> has none of these
rules.

B<Graph schemas are known to the model and are never dropped.>
C<create_graph> makes a PostgreSQL schema (same name as the graph), one table
per label with its indexes and sequences, and an C<_age_cache_invalidate>
trigger on each. None of it has a C<pg_depend> row to the C<age> extension, so
the driver's member filter does not hide it, and a deploy without
C<pg_schemas> would diff it into C<DROP SCHEMA ... CASCADE>. This class tells
the protocol which schemas those are.

The class answers:

=over 4

=item * L</inspect> -- the graphs of C<ag_catalog.ag_graph>, the extension's
state, kept read-only in the model;

=item * L</claims> -- C<< [ schema => $graph_schema ] >> for each graph; the
driver's cascade takes the label tables, their columns, indexes, triggers,
sequences, functions and types with it;

=item * L</activation> -- C<LOAD 'age'> and C<ag_catalog> on the
C<search_path>, as data;

=item * L</storage_layer> -- L<DBIO::PostgreSQL::Age::Storage>, the runtime
surface (C<cypher>, C<create_graph>, ...), which the driver registers for a
declared C<age>.

=back

B<AGE and PostGIS.> The two rule sets are disjoint: AGE takes whole objects
out of the model (phase 1), PostGIS adds attributes to objects that stay
(phase 2). Phase 2 sees the model after the claims, so a geometry column that
lives in a graph schema is gone before PostGIS annotates; no code in either
class is needed for that, and the result does not depend on the order of the
two. AGE has no column rules today. When it gets one, it answers C<undef> for
a column whose type belongs to an active C<postgis> peer, read from
C<< $ctx->{peers}{postgis} >>. The order independence is checked by
L<DBIO::Test::ExtensionSet> (F<t/50-extension-set.t>).

An AGE extension that is not installed has nothing to claim: the probe of
C<ag_catalog.ag_graph> finds no table and the state is empty. The probe is a
plain catalog read; it needs no C<LOAD 'age'> in the session.

=head1 METHODS

=head2 extension_interface

Interface version 1 of L<DBIO::Extension>.

=head2 name

C<age>, the name in C<pg_extension.extname>.

=head2 driver

C<DBIO::PostgreSQL>. An assertion checked after the DSN decided the driver;
the extension never determines it (ADR 0032 section 7).

=head2 inspect

Phase 0. Reads C<ag_catalog.ag_graph> over C<< $ctx->{dbh} >> when
C<to_regclass> finds it and returns

  { graphs => [ { name => 'social', namespace => 'social' }, ... ] }

in the order of the graph names; C<namespace> is the name of the PostgreSQL
schema of the graph. Without the table (extension not installed) the list is
empty.

=head2 claims

Phase 1. C<< [ schema => $namespace ] >> for each graph of the state. The
cascade belongs to the driver.

=head2 activation

C<< { load => 'age', search_path => ['ag_catalog'] } >>. The driver turns it
into C<LOAD 'age'> and the C<search_path> of a new connection, with the
namespace of the connection first.

=head2 storage_layer

C<DBIO::PostgreSQL::Age::Storage>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
