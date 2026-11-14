package DBIO::Test::StorageLayer;
# ABSTRACT: Structural contract check for DBIO storage-extension components and layers

use strict;
use warnings;

our $VERSION = '0.900005';

use mro;
use DBIO::Componentised ();
use Test::More ();
use DBIO::Exception;
use DBIO::Storage::Composed ();

use Exporter 'import';

our @EXPORT_OK = qw(
  storage_layer_contract_ok
  storage_layer_contract_violations
);


sub storage_layer_contract_ok {
  my ($component, $layer, $name) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  $name = defined $name ? $name
    : defined $layer
      ? "$component / $layer honour the ADR 0032 section 7 storage-layer contract"
      : "$component honours the ADR 0032 section 7 storage-layer contract";

  my @violations = storage_layer_contract_violations($component, $layer);

  my $ok = Test::More::ok(!@violations, $name);

  unless ($ok) {
    Test::More::diag($_) for @violations;
    Test::More::diag(
      'ADR 0032 section 7 (hard cut): a DBIO storage extension registers a '
    . 'storage LAYER via DBIO::Schema->register_storage_layer; the schema '
    . 'declares the driver, by its shortcut or component (ADR 0067). The extension '
    . 'never picks the storage class itself -- not via storage_type, not via '
    . 'inheritance. See docs/adr/'
    . '0032-storage-layer-composition-and-async-transport-contract.md in the '
    . 'DBIO core distribution, and DBIO::Storage::Composed "Layer rules".'
    );
  }

  return $ok;
}


sub storage_layer_contract_violations {
  my ($component, $layer) = @_;

  DBIO::Exception->throw(
    'storage_layer_contract_violations requires a component class name'
  ) unless defined $component && length $component && !ref $component;

  DBIO::Exception->throw(
    'storage_layer_contract_violations layer argument must be a class name'
  ) if defined $layer && (ref $layer || !length $layer);

  DBIO::Componentised->ensure_class_loaded($component);
  DBIO::Componentised->ensure_class_loaded($layer) if defined $layer;

  my @violations = (
    _driver_welding_violations($component),
    _storage_type_pin_violations($component),
  );

  push @violations, _layer_violations($layer) if defined $layer;

  return @violations;
}

# --- check 1: the component hangs off no driver -------------------------

sub _driver_welding_violations {
  my ($component) = @_;

  my @ancestors = @{ mro::get_linear_isa($component) };
  shift @ancestors;   # the class itself is always the first rung

  my @violations;
  for my $ancestor (@ancestors) {

    if ($ancestor->isa('DBIO::Storage')) {
      push @violations,
        "$component inherits the storage class $ancestor: a component that IS a "
      . 'storage has already made the storage decision the DSN is supposed to '
      . 'make. Register a storage layer instead.';
      next;
    }

    next unless grep { $_ eq 'connection' }
      DBIO::Storage::Composed->_own_methods($ancestor);

    push @violations,
      "$component inherits the connect hook ${ancestor}::connection (via "
    . join(' -> ', @{ mro::get_linear_isa($component) }[0 .. _isa_index($component, $ancestor)])
    . '). A driver component pins its storage class from connection(); '
    . "inheriting $ancestor inherits that decision and welds the extension to "
    . 'one driver -- and, once a schema class loads both, breaks the C3 merge. '
    . 'This is the dbio-postgresql-age shape.';
  }

  return @violations;
}

# Position of $ancestor in $class's linearised ISA -- used only to print the
# inheritance path that reached it.
sub _isa_index {
  my ($class, $ancestor) = @_;
  my $isa = mro::get_linear_isa($class);
  for my $i (0 .. $#$isa) {
    return $i if $isa->[$i] eq $ancestor;
  }
  return 0;
}

# --- check 2: the component pins no storage_type ------------------------

# Recorded by the probe rungs below. Localised around every probe run.
our @PROBE_STORAGE_TYPE_PINS;
our @PROBE_REGISTERED_LAYERS;

{
  # Most specific rung of the probe: intercepts the two class-data setters a
  # connect hook can reach, whichever package in the chain calls them.
  package # hide from the indexer
    DBIO::Test::StorageLayer::_Recorder;

  sub storage_type {
    my $self = shift;
    if (@_) {
      push @DBIO::Test::StorageLayer::PROBE_STORAGE_TYPE_PINS, $_[0];
      return $_[0];
    }
    return @DBIO::Test::StorageLayer::PROBE_STORAGE_TYPE_PINS
      ? $DBIO::Test::StorageLayer::PROBE_STORAGE_TYPE_PINS[-1]
      : 'DBIO::Storage::DBI';
  }

  sub register_storage_layer {
    my ($self, $layer) = @_;
    push @DBIO::Test::StorageLayer::PROBE_REGISTERED_LAYERS, $layer;
    return $self;
  }

  sub storage_layers { [ @DBIO::Test::StorageLayer::PROBE_REGISTERED_LAYERS ] }

  sub throw_exception { shift; die @_ }
}

{
  # Least specific rung: where the component's next::method chain terminates.
  package # hide from the indexer
    DBIO::Test::StorageLayer::_ConnectTerminal;

  sub connection { return $_[0] }
}

my $probe_seq = 0;

sub _storage_type_pin_violations {
  my ($component) = @_;

  my $probe = __PACKAGE__ . '::_Probe' . ++$probe_seq;
  {
    no strict 'refs';
    @{"${probe}::ISA"} = (
      __PACKAGE__ . '::_Recorder',
      $component,
      __PACKAGE__ . '::_ConnectTerminal',
    );
  }
  mro::set_mro($probe, 'c3');

  local @PROBE_STORAGE_TYPE_PINS = ();
  local @PROBE_REGISTERED_LAYERS = ();

  my $error;
  {
    local $@;
    eval {
      $probe->connection('dbi:DBIO_Test_StorageLayer:probe', '', '', {});
      1;
    } or $error = ($@ || 'unknown error');
  }

  my @violations;

  if (@PROBE_STORAGE_TYPE_PINS) {
    push @violations,
      "$component pins storage_type from its connect path (set to "
    . join(', ', map { defined $_ ? "'$_'" : 'undef' } @PROBE_STORAGE_TYPE_PINS)
    . '). An extension does not choose the storage class -- the DSN does, via '
    . '_determine_driver. Register a storage layer instead. '
    . 'This is the dbio-mysql-ev shape.';
  }
  elsif (defined $error) {
    chomp(my $msg = $error);
    push @violations,
      "$component: its connect hook could not be probed, so the storage_type "
    . "check could not run: $msg. A component's connection() override must be "
    . 'a thin hook -- register a layer, then chain with $self->next::method -- '
    . 'and callable as such.';
  }

  return @violations;
}

# --- check 3: the layer is a real layer ---------------------------------

sub _layer_violations {
  my ($layer) = @_;

  my @violations;

  my @ancestors = @{ mro::get_linear_isa($layer) };
  shift @ancestors;   # the layer itself

  for my $ancestor (@ancestors) {
    next unless $ancestor->isa('DBIO::Storage');
    push @violations,
      "$layer inherits the storage class $ancestor. A layer is a plain method "
    . 'package composed ABOVE the base storage, not a storage subclass beside '
    . 'it -- see DBIO::Storage::Composed "Layer rules". Drop the inheritance '
    . 'and chain into the base with $self->next::method.';
  }

  if (grep { $_ eq 'new' } DBIO::Storage::Composed->_own_methods($layer)) {
    push @violations,
      "$layer defines its own constructor (new). A layer has no constructor: "
    . 'the synthesised class is instantiated through the base storage. See '
    . 'DBIO::Storage::Composed "Layer rules".';
  }

  return @violations;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::StorageLayer - Structural contract check for DBIO storage-extension components and layers

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

In an extension distribution's F<t/00-load.t>:

  use strict;
  use warnings;
  use Test::More;
  use DBIO::Test::StorageLayer qw( storage_layer_contract_ok );

  use_ok 'DBIO::PostgreSQL::Age';
  use_ok 'DBIO::PostgreSQL::Age::Storage';

  # component + layer
  storage_layer_contract_ok(
    'DBIO::PostgreSQL::Age' => 'DBIO::PostgreSQL::Age::Storage',
  );

  done_testing;

An inert marker component that registers no layer at all (C<DBIO::MySQL::EV>,
C<DBIO::PostgreSQL::EV> -- they only tag the schema so the storage MRO can
resolve the C<ev> mode, ADR 0030) passes the layer class as C<undef>, i.e. just
omits it:

  storage_layer_contract_ok('DBIO::MySQL::EV');

The arguments are positional, so a custom test name without a layer spells the
layer C<undef>:

  storage_layer_contract_ok('DBIO::MySQL::EV', undef, 'EV marker stays inert');

=head1 DESCRIPTION

A DBIO storage extension does B<not> pick a driver. It registers a storage
B<layer> (L<DBIO::Schema/register_storage_layer>), the layer is composed over
whatever base storage the DSN resolved to
(L<DBIO::Storage::Composed>, L<DBIO::Storage::DBI/_determine_driver>), and the
extension therefore rides every driver and every transport it is composed onto.
That is the hard cut recorded in B<ADR 0032 section 7> ("Hard cut of the
extension C<storage_type>-override pattern").

This module makes that rule B<mechanical>. Prose did not hold it: the rule was
broken twice in the family, each time with a different mechanism, and each time
it was only caught afterwards by review.

=over 4

=item * B<dbio-mysql-ev> -- C<DBIO::MySQL::EV> overrode
C<connection()> and forced C<< storage_type('+DBIO::MySQL::EV::Storage') >> on
every connect, so the component decided the storage class instead of the DSN.

=item * B<dbio-postgresql-age> -- C<DBIO::PostgreSQL::Age> gained
C<< use base 'DBIO::PostgreSQL' >> to turn one red test assertion green. That
welds the extension to one driver through inheritance rather than through
C<storage_type>, and it produces a genuine C3 regression as soon as the schema
class loads both (C<Inconsistent hierarchy during C3 merge>).

=back

ADR 0032 section 7 names only C<storage_type>, so the inheritance route was
formally uncovered. The checks here are deliberately B<mechanism-independent>:
they ask what the class structurally I<is> and what its connect hook
structurally I<does>, not which spelling was used to get there.

=head1 METHODS

=head2 storage_layer_contract_ok

  storage_layer_contract_ok($component_class);
  storage_layer_contract_ok($component_class, $layer_class);
  storage_layer_contract_ok($component_class, $layer_class, $test_name);

One test: passes when C<$component_class> (and, when given, C<$layer_class>)
satisfy the ADR 0032 section 7 contract described above. On failure the
diagnostic names every violation, its cause, and points at the ADR.

C<$layer_class> is optional -- an inert marker component that registers no layer
(C<DBIO::MySQL::EV>, C<DBIO::PostgreSQL::EV>) is checked on its own. Both classes
are loaded if they are not loaded already.

Returns the boolean the underlying assertion returned.

=head2 storage_layer_contract_violations

  my @violations = storage_layer_contract_violations($component_class, $layer_class);

The assertion-free half of L</storage_layer_contract_ok>: returns the list of
violation descriptions (empty when the contract holds), each a self-contained
sentence naming the offending class and the rule it breaks. Useful when a repo
wants to shape its own assertion around the result, and it is what core's own
suite drives the negative fixtures through.

=head1 WHAT IS CHECKED, AND HOW

=head2 1. The component hangs off no driver

Every class in C<< mro::get_linear_isa($component) >> B<except the component
itself> must be driver-neutral. An ancestor is a violation when it either

=over 4

=item * defines its B<own> C<connection> method, or

=item * is a storage class (C<< ->isa('DBIO::Storage') >>).

=back

C<connection()> is the one seam where a component can decide the storage class,
and it is exactly how every driver component does it -- C<DBIO::PostgreSQL>,
C<DBIO::MySQL> and C<DBIO::SQLite> each override C<connection> to pin
C<< storage_type('+...::Storage') >>. A component that I<inherits> a
C<connection> override has inherited somebody else's storage decision, which is
the C<dbio-postgresql-age> shape precisely. "Defines its own" is resolved
through L<DBIO::Storage::Composed>'s own-method scan (compiled body in that
package), so an imported or inherited sub never counts.

The obvious alternative -- "anything outside C<DBIO::Base> and what core brings
under it is suspicious" -- was tried and rejected on evidence: a well-behaved
component reaches core classes far outside that chain through ordinary
C<load_components>. C<DBIO::PostgreSQL::PostGIS> linearises as
C<< PostGIS, DBIO::InflateColumn, DBIO::Row, DBIO::Base, ... >> because it loads
the C<InflateColumn> component. A namespace/baseline rule flags that; the
connect-hook rule does not, because neither C<DBIO::InflateColumn> nor
C<DBIO::Row> touches the connect path. The sharper question ("does this ancestor
carry a storage decision?") is the one worth asking.

For the same reason this check does B<not> require the component to derive from
C<DBIO::Base>. C<load_components> only unshifts a component into the consuming
class's C<@ISA>; a component with an empty C<@ISA> composes and resolves exactly
like one that inherits C<DBIO::Base>. Requiring a base here would fail a component that pins nothing
and welds to nothing, which is not what ADR 0032 section 7 is about.

=head2 2. The component pins no C<storage_type>

Checked by B<running> the connect hook, not by reading source. A throwaway probe
class is synthesised with

  @ISA = ( <recorder>, $component, <terminal> )

under the C<c3> MRO. The recorder is the most specific rung, so every
C<< $self->storage_type(...) >> and C<< $self->register_storage_layer(...) >>
made anywhere in the chain resolves to it and is recorded; the terminal is the
least specific rung and supplies the final C<connection> that the component's
C<< $self->next::method(@_) >> lands on. Then C<< $probe->connection($dsn) >> is
called and the recording is inspected: any C<storage_type> B<setter> call is the
violation.

This is a structural probe rather than a source grep, and it catches both
incidents through the one mechanism that matters -- C<dbio-mysql-ev> directly
(the component's own hook pins), and C<dbio-postgresql-age> too (the inherited
driver's hook pins, reached through the probe's MRO). It is safe to run:
C<connection()> in DBIO never opens a database handle, it only resolves and
stores the storage object, and the probe's recorder/terminal keep even that
from happening.

Two limits, stated rather than hidden:

=over 4

=item * only pinning reachable from C<connection()> is seen. A component that
set C<storage_type> from some other hook (C<import>, a class-level statement)
would pass this check. No incident took that route, and both known ones are
covered.

=item * if the probe call dies, that is reported as a violation naming the
exception. A component's connect hook is a thin hook -- register a layer, chain
with C<next::method> -- and one that cannot be called as such is a finding, not
something to swallow silently.

=back

=head2 3. The layer is a real layer

Only when a layer class is given. These are the rules L<DBIO::Storage::Composed>
states under I<Layer rules>:

=over 4

=item * no C<@ISA> pointing at a storage -- no ancestor may satisfy
C<< ->isa('DBIO::Storage') >> (which covers C<DBIO::Storage::DBI>, every driver
storage, and C<DBIO::Storage::Async>). A layer is mixed in B<above> the base, not
beside it.

=item * no constructor -- the layer must not define its own C<new>. The
synthesised class inherits the base storage's constructor; a layer that brings
one is a storage class wearing a layer's name.

=back

The own-method scan reuses C<< DBIO::Storage::Composed->_own_methods >>, the same
routine the compose-time collision check uses. It stays a core-internal call --
nothing of C<DBIO::Storage::Composed>'s internals is re-exported from here.

=head1 NAMES A LAYER WRITES

A layer that issues statements about a schema, a database extension or a
library (C<_set_connection_schema>, C<_activate_extensions>, an extension's
install and load) handles every such name as an B<identifier> (ADR 0077). It
writes the name into a statement only through the driver's identifier quoting
(or as a bind) and refuses with a L<DBIO::Exception> a name it cannot write
that way. It never joins a name into the statement text by string
concatenation. The checks above are structural and do not see this; the
Names list of L<DBIO::Test::Conformance> does, in the driver's conformance
run.

=head1 SEE ALSO

L<DBIO::Storage::Composed>, L<DBIO::Schema/register_storage_layer>,
L<DBIO::Storage::DBI>.

ADR 0032 in the DBIO core distribution's F<docs/adr/>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
