package DBIO::PostgreSQL::PostGIS::Topology::Extension;
# ABSTRACT: The postgis_topology extension: its topologies are runtime schemas, not the application's

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';


sub extension_interface { 1 }

sub name { 'postgis_topology' }

sub driver { 'DBIO::PostgreSQL' }


sub inspect {
  my ($class, $ctx) = @_;
  my $dbh = $ctx->{dbh} or return undef;

  my $schema = ($ctx->{self} // {})->{schema};
  $schema = 'topology' unless defined $schema;
  my $table  = $dbh->quote_identifier($schema) . '.' . $dbh->quote_identifier('topology');

  my ($found) = $dbh->selectrow_array('SELECT to_regclass(?)', undef, $table);
  return undef unless defined $found;

  my $rows = $dbh->selectall_arrayref(
    "SELECT name, srid FROM $table ORDER BY name"
  );
  return { topologies => [ map { { name => $_->[0], srid => $_->[1] } } @$rows ] };
}


sub claims {
  my ($class, $model, $ctx) = @_;
  my $state = ($ctx->{self} // {})->{state} or return [];
  return [ map { [ schema => $_->{name} ] } @{ $state->{topologies} // [] } ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Topology::Extension - The postgis_topology extension: its topologies are runtime schemas, not the application's

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions('postgis', 'postgis_topology');

=head1 DESCRIPTION

One engine extension, one entry, one class (ADR 0066, Decisions, 7):
C<postgis_topology> is its own extension in C<pg_extension>, apart from
C<postgis>, and is declared apart from it.

B<Topologies are runtime schemas.> C<CREATE EXTENSION postgis_topology> makes
the schema C<topology> with the tables C<topology.topology> and
C<topology.layer>; those are members of the extension. C<topology.CreateTopology('name', srid)>
adds a row to C<topology.topology> and creates B<a schema> of that name, holding
C<edge_data>, C<face>, C<node>, C<relation>, the view C<edge> and their
sequences and indexes. None of these has a C<pg_depend> membership in the
extension (measured on PostGIS 3.6), so the driver's base filter does
not keep them out of the model: without claims a deploy would take them for the
application's tables and drop them. This class claims the schemas, the same way
Apache AGE claims its graph schemas.

The class does nothing else. A topology layer (C<topology.layer>, the
C<topogeometry> columns of the application's own tables) stays the
application's.

=head1 METHODS

=head2 extension_interface

Returns C<1>.

=head2 name

Returns C<postgis_topology>.

=head2 driver

Returns C<DBIO::PostgreSQL>.

=head2 inspect

Phase 0. Probes C<topology.topology> (in the schema of the installed
extension, C<topology> by default) with C<to_regclass> and reads the
topologies: C<< { topologies => [ { name => ..., srid => ... } ] } >>, ordered
by name; the schema of a topology has the name of the topology. C<undef> when
the table is not there (the extension is not installed). Read-only.

=head2 claims

Phase 1. C<< [ schema => $name ] >> for each topology of the extension's own
state; the driver's cascade takes the tables, columns, indexes, sequences and
views of the schema. C<[]> without state.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
