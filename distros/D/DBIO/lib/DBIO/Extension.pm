package DBIO::Extension;
# ABSTRACT: Base class of a database extension (PostGIS, AGE, pgvector, ...) known to deploy, introspection and diff

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Exception;

# The extension interface (ADR 0066 section 5.3). INTERFACE_CURRENT is the
# version this core implements; @INTERFACE_VERSIONS is the set it accepts.
# Until the family's first release the set is exactly the current version;
# afterwards it holds the current and the previous one for one release, and
# that is a change of this list only.
our $INTERFACE_CURRENT = 1;
our @INTERFACE_VERSIONS = (1);


sub extension_interface { undef }


sub name { undef }


sub driver { undef }


sub inspect { undef }


sub claims { [] }


sub annotate { [] }


sub verdict { undef }


sub activation { undef }


sub storage_layer { undef }


sub components { () }



sub interface_current { $INTERFACE_CURRENT }


sub interface_versions { @INTERFACE_VERSIONS }


sub check_interface {
  my ($self, $class) = @_;

  DBIO::Exception->throw("Extension class '" . ($class // 'undef') . "' does not derive from DBIO::Extension")
    unless defined $class && !ref $class && $class->isa(__PACKAGE__);

  my $version  = $class->extension_interface;
  my @accepted = $self->interface_versions;

  DBIO::Exception->throw(
    "Extension $class states no extension_interface; this DBIO core supports "
    . "interface version(s) " . join(', ', @accepted)
    . ". Add 'sub extension_interface { $INTERFACE_CURRENT }' to the extension."
  ) unless defined $version;

  return 1 if grep { $_ eq $version } @accepted;

  my ($min, $max) = (sort { $a <=> $b } @accepted)[0, -1];
  my $side = $version > $max
    ? 'upgrade DBIO core'
    : 'upgrade the extension';
  DBIO::Exception->throw(
    "Extension $class implements interface version $version; this DBIO core "
    . "supports interface version(s) " . join(', ', @accepted) . ". To fix: $side."
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Extension - Base class of a database extension (PostGIS, AGE, pgvector, ...) known to deploy, introspection and diff

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  package MyApp::DB::Extension::Vector;
  use base 'DBIO::Extension';

  sub extension_interface { 1 }
  sub name   { 'vector' }
  sub driver { 'DBIO::PostgreSQL' }

  sub verdict {
    my ($class, $change, $ctx) = @_;
    return undef unless $change->{kind} eq 'column_type'
      && ($change->{old_info}{data_type} // '') =~ /\bvector\(/;
    return { refuse => "column $change->{column_name}: the dimension of a vector is not converted" };
  }

=head1 DESCRIPTION

A database extension adds to a database what the application's schema does not
declare: types, functions, operators and, for some extensions, objects in the
application's own namespaces that the engine does not record as the
extension's. Deploy, introspection and diff need three answers for each
extension a database holds: which objects belong to the application model and
which to the extension, what the extension adds to an object of the model, and
how a change of such an object is written or refused (ADR 0066).

A DBIO extension is a class deriving from this one. B<Every method has a
default that does nothing>, so an extension writes only what it needs. All
methods are class methods; anything an extension knows about the database
comes through the context C<$ctx> (see L</THE CONTEXT>).

The list of extensions a schema has is built by L<DBIO::Extension::List>, the
phases and their merges are run by L<DBIO::Extension::Protocol>, and
L<DBIO::Deploy::Base> runs the protocol around introspection and diff. The
commutativity test for an extension set is L<DBIO::Test::ExtensionSet>.

=head1 METHODS

=head2 extension_interface

  sub extension_interface { 1 }

The extension interface version the class implements. B<Required>: the default
returns C<undef>, which L</check_interface> refuses.

=head2 name

  sub name { 'postgis' }

The engine's own name of the extension: C<pg_extension.extname>, the DuckDB
extension name, the SQLite module name. One class per engine extension, one
entry per name. The default is C<undef>: a plain class that serves several
names (the driver's class for extensions without rules) states none, and the
name of the list's entry stands. When a class states a name that differs from
the entry's, the list refuses.

=head2 driver

  sub driver { 'DBIO::PostgreSQL' }

The driver the extension belongs to, as an B<assertion>. The extension never
determines the driver (ADR 0032 section 7): it is compared with the resolved
driver by L<DBIO::Extension::List/check_driver>, after the DSN has decided the
driver and never at C<connect>. The default C<undef> asserts nothing.

=head2 inspect

  sub inspect { my ($class, $ctx) = @_; ... }   # phase 0

The only method with database access: C<< $ctx->{dbh} >> is the handle the
deploy works on. Returns the extension's state as a plain, copyable structure
(AGE: C<< { graphs => [ { name => ..., namespace => ... } ] } >>) or C<undef>
for none. Core keeps it per extension under its name (C<< $ctx->{self}{state} >>
in later phases, C<< $ctx->{peers}{$name}{state} >> for the others) and the
driver may put it into the model, read-only. A deploy never creates or drops
it. Default: C<undef>.

=head2 claims

  sub claims { my ($class, $model, $ctx) = @_; ... }   # phase 1

Returns an array reference of B<addresses> (see L</ADDRESSES>) of objects that
are the extension's and not the application's (AGE: C<< [ schema => $graph_schema ] >>
for each graph). C<$model> is the driver's base model, as the driver's
introspection or target build produced it. The method reads; it does not
change the model. Default: C<[]>.

=head2 annotate

  sub annotate { my ($class, $model, $ctx) = @_; ... }   # phase 2

Returns an array reference of C<< [ $address, $attribute, $value ] >> triples
for objects that stay in the model (PostGIS: C<base_type>, C<geometry_type>,
C<srid> on a column whose type lives in the PostGIS schema). C<$model> is the
model B<after> phase 1, so objects another extension claimed are no longer in
it. C<$attribute> is a plain string, C<$value> a plain scalar (or a structure
comparable as data). Default: C<[]>.

=head2 verdict

  sub verdict { my ($class, $change, $ctx) = @_; ... }   # phase 3

Asked by the driver for a change it is about to write. C<$change> is the
driver's description of one change; the driver's POD states its keys. The
column type change that is the case today has the form

  { kind        => 'column_type',
    table       => $table_key,
    column_name => $column,
    old_info    => \%column_info,    # incl. the annotations of phase 2
    new_info    => \%column_info }

C<< $ctx->{models} >> holds the source and target model after phase 2. Returns

=over 4

=item * C<undef> -- not mine, the extension has no opinion,

=item * C<< { using => $expr } >> -- the change is written with this C<USING> expression (or the driver's equivalent), or

=item * C<< { refuse => $message } >> -- the change is refused, with this message.

=back

Anything else is a malformed answer and throws. Default: C<undef>.

=head2 activation

  sub activation { my ($class, $ctx) = @_; ... }

Per connection, as B<data, not statements>: a hash reference with the keys

=over 4

=item * C<load> -- a library name, an array reference of them, or a hash
reference C<< { $name => $library } >>. A bare library name stands for
itself (C<< 'age' >> is C<< { age => 'age' } >>).

=item * C<search_path> -- a schema name or an array reference of them.

=back

No other key is accepted. The driver turns the merged activation of all active
extensions into the statements of a new connection (PostgreSQL: C<LOAD 'age'>
and the C<search_path>, the namespace of the connection first and the
extensions' entries in name order after it). Default: C<undef>, nothing.

=head2 storage_layer

  sub storage_layer { 'DBIO::PostgreSQL::Age::Storage' }

The storage layer (ADR 0032) that carries the extension's runtime surface
(AGE: C<cypher>, C<create_graph>), or C<undef>. The driver registers it for a
declared extension that names one. Default: C<undef>.

=head2 components

  sub components { 'DBIO::PostgreSQL::PostGIS' }

An B<optional> class method outside interface version 1: the result-side parts
of the extension, as a list of component class names (PostGIS: the geometry
inflation component). The driver applies them to the schema for a declared
extension, as C<load_components> would. Default: the empty list. A new optional
method with a do-nothing default does not change the interface version (see
L</INTERFACE VERSION>), so an extension that does not need it never mentions
it.

=head2 interface_current

  my $v = DBIO::Extension->interface_current;

The interface version this core implements.

=head2 interface_versions

  my @accepted = DBIO::Extension->interface_versions;

The set of interface versions this core accepts. Until the family's first
release exactly the current version; afterwards the current and the previous
one for one release.

=head2 check_interface

  DBIO::Extension->check_interface($class);

Throws a L<DBIO::Exception> unless C<$class> derives from this class and its
C<extension_interface> is in L</interface_versions>. The message names the
extension, its version, core's set and the side to upgrade. Returns true.

=head1 THE INTERFACE

=head2 Identity

=head2 Phases

Every phase method receives the same input for every active extension, as a
copy, and returns data. See L</PHASES AND MERGES>.

=head2 Beyond the interface

=head1 THE CONTEXT

C<$ctx> carries, for one deploy and one connection, a fresh copy for every
call:

=over 4

=item C<dbh>

Only in L</inspect>. The database handle of the deploy.

=item C<peers>

The other active entries, name to
C<< { class, installed, version, schema, state } >>. C<installed> is true when
the database has the extension, C<version> and C<schema> are what the driver
read (C<undef> when it did not), C<state> is the peer's L</inspect> result
(C<undef> while phase 0 runs and for a peer without state). The peers are how
an extension regulates its interaction with another one, inside its own code.

=item C<self>

The extension's own entry: C<< { name, class, options, installed, version,
schema, state } >>. C<options> are the options of the declaration.

=item C<driver>

A hash reference of the driver's helpers an extension may use. The driver's POD
names them (PostgreSQL: C<quote_ident>, C<qualified_key>, the address
constructors). Core passes the hash through and promises nothing about its
content. Not copied: it holds code references.

=item C<connection_schema>

The namespace of the connection (ADR 0065), or C<undef>.

=item C<restricted>

True when the deploy is restricted to the schemas it manages.

=item C<models>

Only in L</verdict>: C<< { source => $model, target => $model } >> after
phase 2.

=back

=head1 PHASES AND MERGES

The phases run in a fixed sequence. Within a phase B<every extension reads the
same input> and returns data; core merges.

  phase        input of every extension      merge                          conflict
  0 inspect    the connection                per extension, by name         none
  1 claims     the driver's base model       union of addresses             none
  2 annotate   the model after phase 1       union of triples               same address+attribute,
                                                                            two values: refuses
  3 verdict    the change, models of 2       at most one answer per change  two different answers
                                                                            refuse; any refuse refuses
                                                                            the diff, all listed
  activation   the context                   the driver composes            the driver refuses what
                                                                            it cannot compose

Phases 1 and 2 run on both sides of a diff, the live model and the target
model, with the same set. The list is ordered by C<name>; the order decides
only the sequence of messages and of statements that do not depend on each
other. No result depends on it.

=head1 ADDRESSES

An address is the driver's: C<< [ schema => $name ] >>, C<< [ table => $key ] >>,
C<< [ column => $table_key, $column ] >>, C<< [ type => $key ] >> and so on. The
driver's POD lists its kinds and its cascade (a claimed schema takes its
tables, a table its columns, indexes, triggers, keys). Core treats an address
as an opaque array reference of scalars: it sorts, de-duplicates and compares
it, and hands it back to the driver unchanged.

=head1 WRITING AN EXTENSION

A third extension needs no change in core, in the driver or in another
extension: a class, and the declaration naming it.

  package MyApp::DB::Extension::Vector;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'vector' }
  sub driver { 'DBIO::PostgreSQL' }
  # ... the methods above that the extension needs ...

  package MyApp::DB;
  use DBIO Schema => -pg;
  __PACKAGE__->pg_extensions(vector => { class => 'MyApp::DB::Extension::Vector' });

An extension with result-side parts (a column inflation component) names them
in L</components>; the driver applies them for a declared extension. It is
optional and outside the interface version.

The rules for every extension, family or not:

=over 4

=item 1. One class per engine extension; C<name> is the engine's name.

=item 2. It states C<extension_interface> and C<driver>, and derives from
C<DBIO::Extension>.

=item 3. Only L</inspect> touches the database. The other methods are
functions of their arguments: no changes to the input, no state between
calls, no globals.

=item 4. It never determines the driver (ADR 0032 section 7), changes no
C<@ISA> of a storage, Deploy or Introspect class, and registers nothing into a
driver registry.

=item 5. It answers only for what is its own. Where another extension's
presence changes its answer, it reads C<< $ctx->{peers} >>; it does not ask
core for an order.

=item 6. It passes L<DBIO::Test::ExtensionSet> over itself and the extensions
it names as peers.

=back

The test:

  use DBIO::Test::ExtensionSet qw(extension_set_ok);

  extension_set_ok(
    driver     => 'DBIO::PostgreSQL::Deploy',
    extensions => [ 'MyApp::DB::Extension::Vector', 'DBIO::PostgreSQL::PostGIS::Extension' ],
    source     => $live_model_fixture,
    target     => $target_model_fixture,
    changes    => [ { kind => 'column_type', ... } ],
  );

It runs the phases in every permutation of the set, asserts the same
post-phase models, diff statements and activation, and the same output of
every extension in every position, and fails when an extension changed its
input.

=head1 INTERFACE VERSION

C<DBIO::Extension> carries the interface version core implements
(L</interface_current>) and the set it accepts (L</interface_versions>). A
version outside the set refuses when the driver resolves the list
(L</check_interface>), with a L<DBIO::Exception>; there is no warning mode. A
new optional method with a do-nothing default does not change the version; a
changed signature, a changed meaning of a return value or a new required
method does.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
