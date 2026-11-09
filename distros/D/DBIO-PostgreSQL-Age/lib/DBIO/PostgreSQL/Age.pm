package DBIO::PostgreSQL::Age;
# ABSTRACT: Apache AGE graph database support for DBIO::PostgreSQL
our $VERSION = '0.900004';

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->register_storage_layer('DBIO::PostgreSQL::Age::Storage');
  return $self->next::method(@info);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age - Apache AGE graph database support for DBIO::PostgreSQL

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->pg_extensions('age');
  __PACKAGE__->load_components('PostgreSQL::Age');

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

  $schema->storage->create_graph('social');

  my $rows = $schema->storage->cypher(
    'social',
    q{ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name },
    [qw( person friend )],
  );

=head1 DESCRIPTION

L<DBIO::PostgreSQL::Age> is the overview of the Apache AGE support in
L<DBIO::PostgreSQL>. Apache AGE is a PostgreSQL extension that adds openCypher
graph query capabilities via the C<cypher()> SQL function.

B<The extension is declared in the list.> A schema says that its database has
AGE with C<< __PACKAGE__->pg_extensions('age') >> (ADR 0066 of DBIO core). The
driver resolves the name to L<DBIO::PostgreSQL::Age::Extension>, which holds
everything the model needs to know about AGE (the graph schemas), names the
activation of a connection (C<LOAD 'age'>, C<ag_catalog> on the C<search_path>)
and names the storage layer L<DBIO::PostgreSQL::Age::Storage> with the runtime
surface (graph lifecycle and Cypher). The schema names its driver
(C<use DBIO 'Schema', -pg>); this component declares none, and neither does the
extension class.

B<Open until the driver resolves the list.> Today this component still
registers L<DBIO::PostgreSQL::Age::Storage> as a storage B<layer> (via
L<DBIO::Schema/register_storage_layer>), and C<load_age> (below) is still the
connection callback; the driver registers the layer of every declared extension
that names one and composes the activation of the list in the connect path
(ADR 0066 section 3). Both go from here when it does.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to register L<DBIO::PostgreSQL::Age::Storage> as a
storage layer (L<DBIO::Schema/register_storage_layer>) before connecting, so it
is composed over the resolved driver storage rather than replacing it. This is
what lets AGE stack with other PostgreSQL storage-layer extensions and ride
every async transport its layer is composed onto.

=head1 CONNECTION SETUP

Apache AGE requires C<LOAD 'age'> and C<ag_catalog> on the C<search_path>
on each database connection before any graph operations; C<load_age> puts
C<ag_catalog> in front of the existing path instead of replacing it. Use the C<load_age>
connection callback:

  MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

=head1 DEPLOYING BESIDE AGE

Graphs are not part of the schema model of L<DBIO::PostgreSQL>: they are made
with L<DBIO::PostgreSQL::Age::Storage/create_graph> (and loaded with
Cypher), not by C<< $schema->deploy >>. But the objects C<create_graph>
leaves in the database -- the graph's schema, a table per label, sequences,
the C<_age_cache_invalidate> triggers -- have no C<pg_depend> row to the
extension, so a plain deploy without C<pg_schemas> would diff them into
C<DROP SCHEMA ... CASCADE>.

B<Graph schemas are known to the model and are never dropped.> With

  __PACKAGE__->pg_extensions('age');

the list of the schema holds L<DBIO::PostgreSQL::Age::Extension>: its
C<inspect> reads C<ag_catalog.ag_graph>, its C<claims> name each graph schema
(C<< [ schema => $name ] >>), and the driver removes the claimed schemas with
their tables, columns, indexes, triggers, sequences, functions and types from
both sides of the diff. The declaration also makes the temporary database the
target model is built in create the extension. C<pg_schemas> remains possible
on top and does what it does for L<DBIO::PostgreSQL::Deploy>.

Beside L<DBIO::PostgreSQL::PostGIS> the protocol keeps the result independent
of the order of the declaration: AGE takes whole objects out (phase 1), PostGIS
annotates the columns that stay (phase 2), see
L<DBIO::PostgreSQL::Age::Extension/DESCRIPTION>.
L<DBIO::PostgreSQL::Age::Deploy> and L<DBIO::PostgreSQL::Age::Introspect> are
stubs; no deploy class is chained any more.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - Base PostgreSQL driver component

=item * L<DBIO::PostgreSQL::Age::Extension> - the extension class: graphs, claims, activation

=item * L<DBIO::PostgreSQL::Age::Storage> - Storage class with graph methods

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
