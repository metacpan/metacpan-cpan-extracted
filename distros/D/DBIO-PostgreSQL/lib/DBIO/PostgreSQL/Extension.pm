package DBIO::PostgreSQL::Extension;
# ABSTRACT: The extension class of a PostgreSQL extension without rules, and the driver's table of the family's classes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';

# The driver's fixed table of the extensions the family ships a class for
# (ADR 0066 section 1.2): the engine's name to [ class, distribution ]. The
# table maps names to existing classes, nothing is derived from a name. A
# declaration that names a class of its own wins over it.
our %FAMILY = (
  age              => [ 'DBIO::PostgreSQL::Age::Extension',               'DBIO-PostgreSQL-Age'     ],
  postgis          => [ 'DBIO::PostgreSQL::PostGIS::Extension',           'DBIO-PostgreSQL-PostGIS' ],
  postgis_topology => [ 'DBIO::PostgreSQL::PostGIS::Topology::Extension', 'DBIO-PostgreSQL-PostGIS' ],
);


sub extension_interface { 1 }


sub driver { 'DBIO::PostgreSQL' }


sub family_class {
  my ($class, $name) = @_;
  my $entry = $FAMILY{$name // ''} or return;
  return @$entry;
}


sub resolve_list {
  my ($class, $schema, %opt) = @_;
  return undef unless $schema;

  require DBIO::PostgreSQL::DDL;
  my $schemas = DBIO::PostgreSQL::DDL::_schema_decl($schema, 'pg_extension_schemas') // {};
  my $classes = DBIO::PostgreSQL::DDL::_schema_decl($schema, 'pg_extension_classes') // {};

  my @declaration;
  for my $name (DBIO::PostgreSQL::DDL::_schema_decl($schema, 'pg_extensions')) {
    my %options;
    $options{schema} = $schemas->{$name} if defined $schemas->{$name};
    $options{class}  = $classes->{$name} if defined $classes->{$name};
    push @declaration, $name, (%options ? \%options : ());
  }
  return undef unless @declaration;

  require DBIO::Extension::List;
  my $list = DBIO::Extension::List->new(
    declaration => \@declaration,
    class_table => sub { $class->family_class($_[0]) },
    plain_class => __PACKAGE__,
  );
  $list->check_driver('DBIO::PostgreSQL') if $opt{check_driver} // 1;
  return $list;
}


sub driver_helpers {
  require DBIO::PostgreSQL::Util;
  require DBIO::PostgreSQL::Introspect;
  my $key = sub { @_ > 1 ? DBIO::PostgreSQL::Introspect->qualified_key(@_) : $_[0] };
  return {
    quote_ident     => \&DBIO::PostgreSQL::Util::quote_ident,
    quote_qualified => \&DBIO::PostgreSQL::Util::quote_qualified,
    qualified_key   => sub { DBIO::PostgreSQL::Introspect->qualified_key(@_) },
    schema          => sub { [ schema => $_[0] ] },
    table           => sub { [ table => $key->(@_) ] },
    type            => sub { [ type => $key->(@_) ] },
    column          => sub {
      my $column = pop;
      return [ column => $key->(@_), $column ];
    },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Extension - The extension class of a PostgreSQL extension without rules, and the driver's table of the family's classes

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # A schema declares the extensions its database has; nothing else is written.
  __PACKAGE__->pg_extensions('age', postgis => { schema => 'gis' }, 'citext');

  # An extension outside the family names its class
  __PACKAGE__->pg_extensions(vector => { class => 'MyApp::DB::Extension::Vector' });

=head1 DESCRIPTION

The extension classes of L<DBIO::PostgreSQL/pg_extensions> (ADR 0066 of
DBIO core). This class is the B<plain> one: it has no rules, so an extension
that is declared with it is installed and kept and nothing else is done for it
(C<citext>, C<pgcrypto>, C<pg_trgm>, ...). It derives from L<DBIO::Extension>,
whose defaults do nothing, and states only the interface version and the
driver it belongs to. Its C<name> is C<undef> on purpose: one class serves
every name the table and the declaration do not know, and the name of the list's
entry stands (L<DBIO::Extension/name>).

=head2 The table of the family

The driver names the classes the family ships; the class is loaded when the
list is resolved (the first deploy that needs it), and a distribution that is
not installed refuses with its name:

  name               class                                                distribution
  age                DBIO::PostgreSQL::Age::Extension                     DBIO-PostgreSQL-Age
  postgis            DBIO::PostgreSQL::PostGIS::Extension                 DBIO-PostgreSQL-PostGIS
  postgis_topology   DBIO::PostgreSQL::PostGIS::Topology::Extension       DBIO-PostgreSQL-PostGIS

C<postgis_topology> is an engine extension of its own and gets a class of its
own, in the distribution of PostGIS (the class name is the driver's choice and
fixed here, for the distribution to follow). C<vector> is B<not> in the table:
what the driver does for pgvector -- the column type, the inflation, the
nearest-neighbour query -- is done by the result and result set components from
the column's type, not by a rule of the deploy, and the driver has no rule of
the deploy to move into a class. C<vector> is therefore a plain extension. A
class of its own for it (a dimension that changes is refused, say) is a class
the application names: C<< vector => { class => 'MyApp::DB::Extension::Vector' } >>,
and the family can add it to the table when it ships one.

=head2 postgis_topology

Measured on PostgreSQL 18 with PostGIS 3.6 in a database of its own
(F<t/149-postgis-topology-runtime-schemas-live.t> keeps it true):

=over 4

=item *

C<CREATE EXTENSION postgis_topology> makes the schema C<topology>. Its tables
(C<layer>, C<topology>) and its sequence are members of the extension
(C<pg_depend> deptype C<e>); the schema is not -- the extension depends on it,
and C<DROP EXTENSION> leaves it behind.

=item *

C<topology.CreateTopology('t1')> makes a B<runtime schema> C<t1> with the tables
C<edge_data>, C<face>, C<node>, C<relation>, a view C<edge>, sequences and a
trigger on C<relation>. B<None of them is a member of the extension>, nor is the
schema: they are ordinary objects of the database. A deploy sees them as model
objects -- schema, tables, view, trigger, sequences -- exactly as it sees the
tables of the application.

=item *

C<DROP EXTENSION postgis_topology> is refused while a topology exists (a trigger
of C<t1.relation> depends on a function of the extension), and it does not take
the topology along.

=back

What that means for a deploy with this version of the driver:

=over 4

=item *

postgis_topology B<undeclared>, unrestricted deploy: the diff drops the
topology's objects as model objects (trigger, view, tables, then the
extensions, then the schemas C<t1> and C<topology>), in an order that applies;
it is in the summary, line by line. A restricted deploy keeps all of it.

=item *

postgis_topology B<declared>, unrestricted deploy: C<t1> is a schema the
target model does not have, so the diff B<drops it> with everything in it,
data included. That is the danger. The plain class, which is what
C<postgis_topology> gets until the PostGIS distribution ships
C<DBIO::PostgreSQL::PostGIS::Topology::Extension>, does not prevent it.

=back

B<Recommendation> for the distribution's class: C<inspect> reads
C<topology.topology> (name per topology) when the extension is installed, and
C<claims> returns C<< [ schema => $name ] >> for each -- the way AGE claims its
graph schemas. The driver's cascade then takes the tables, view, trigger and
sequences of the schema out of both models, and the deploy neither creates nor
drops them. The schema C<topology> itself needs no claim: the target model
creates it with the extension and the diff leaves it alone. No code in the
driver is needed for this beyond the table entry that is there.

=head1 METHODS

=head2 extension_interface

The interface version of L<DBIO::Extension>, 1.

=head2 driver

C<DBIO::PostgreSQL>, the assertion that is checked once the DSN has decided
the driver (L<DBIO::Extension::List/check_driver>).

=head2 family_class

  my ($class, $distribution) = DBIO::PostgreSQL::Extension->family_class('postgis');

The table of the family: the class and the distribution that ships it for a
name the family has a class for, the empty list for any other name. This is
the C<class_table> L<DBIO::PostgreSQL::Deploy/_extension_list> hands to
L<DBIO::Extension::List>.

=head2 resolve_list

  my $list = DBIO::PostgreSQL::Extension->resolve_list($schema);
  my $list = DBIO::PostgreSQL::Extension->resolve_list($schema, check_driver => 0);

The one place that turns the declaration of a schema (class or instance;
L<DBIO::PostgreSQL/pg_extensions>, C<pg_extension_schemas>,
C<pg_extension_classes>) into a L<DBIO::Extension::List>: the family table, the
option C<class>, the plain class. Classes are loaded and their interface
version is checked. Returns C<undef> for a schema that declares none.

Unless C<check_driver> is false the driver assertion of every class is checked
as well (L<DBIO::Extension::List/check_driver>); that is for a caller that runs
after the driver is resolved -- the deploy, a new connection. Only the
registration of the storage layers at C<connection> passes false: the layer is
chosen before the DSN has decided anything, and the assertion waits for the
first use.

=head2 driver_helpers

The helpers every extension gets as C<< $ctx->{driver} >>, see
L<DBIO::PostgreSQL::Deploy/Addresses>: C<quote_ident>, C<quote_qualified>,
C<qualified_key> and the address constructors C<schema>, C<table>, C<column>
and C<type>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
