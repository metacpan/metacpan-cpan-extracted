# ABSTRACT: DBIO::Test::StorageLayer -- ADR 0032 section 7 held mechanically
use strict;
use warnings;

use Test::More;

use DBIO::Test::StorageLayer qw(
  storage_layer_contract_ok
  storage_layer_contract_violations
);

# ADR 0032 section 7 says an extension registers a storage LAYER and lets the
# DSN pick the driver. The rule was broken twice in the family, each time with
# a DIFFERENT mechanism and each time caught only afterwards by review:
#
#   dbio-mysql-ev       -- connection() override pinning storage_type
#   dbio-postgresql-age -- use base 'DBIO::PostgreSQL'
#
# What this file encodes is not "the helper emits ok": it is that the rule is
# mechanism-INDEPENDENT. Both historical shapes are rebuilt below as fixtures,
# and the contract check has to find each of them without knowing which
# spelling was used -- while leaving the three legitimate shapes (component +
# layer, inert marker component, plain layer) alone.

# ---------------------------------------------------------------------------
# fixtures
# ---------------------------------------------------------------------------

# A driver component, in the shape every real one has: DBIO::PostgreSQL,
# DBIO::MySQL and DBIO::SQLite all override connection() to pin their storage.
{
  package T::SLC::DriverComponent;
  use base 'DBIO::Base';
  sub connection {
    my ($self, @info) = @_;
    $self->storage_type('+T::SLC::DriverComponent::Storage');
    return $self->next::method(@info);
  }
}

# A well-formed layer: plain method package, no @ISA, no constructor, chains
# into the base with next::method.
{
  package T::SLC::Layer;
  use mro 'c3';
  sub layer_only { 'layer' }
  sub txn_begin {
    my $self = shift;
    return $self->next::method(@_);
  }
}

# The good case: a component that registers a layer and decides nothing.
{
  package T::SLC::CleanComponent;
  use base 'DBIO::Base';
  sub connection {
    my ($self, @info) = @_;
    $self->register_storage_layer('T::SLC::Layer');
    return $self->next::method(@info);
  }
}

# The other good case: an inert marker component. DBIO::MySQL::EV and
# DBIO::PostgreSQL::EV register nothing at all -- they only tag the schema so
# the storage MRO can resolve the 'ev' mode (ADR 0030). There is no layer class
# to hand to the checker, which is exactly why the layer argument is optional.
{
  package T::SLC::InertComponent;
  use base 'DBIO::Base';
  sub inert_marker { 1 }
}

# And the shape DBIO::PostgreSQL::Age actually has at HEAD: a component with an
# EMPTY @ISA. load_components only unshifts a component into the consuming
# class's @ISA, so this resolves exactly like one that inherits DBIO::Base. It
# pins nothing and welds to nothing, so it must pass -- this fixture is here to
# stop a later "components must derive from DBIO::Base" rule from being added
# without someone first deciding that Age should gain a base class.
{
  package T::SLC::BaselessComponent;
  sub connection {
    my ($self, @info) = @_;
    $self->register_storage_layer('T::SLC::Layer');
    return $self->next::method(@info);
  }
}

# dbio-mysql-ev, rebuilt: the component pins the storage class from its hook.
{
  package T::SLC::PinningComponent;
  use base 'DBIO::Base';
  sub connection {
    my ($self, @info) = @_;
    $self->storage_type('+T::SLC::PinningComponent::Storage');
    return $self->next::method(@info);
  }
}

# dbio-postgresql-age, rebuilt: the component inherits a driver component. It
# registers its layer correctly and never mentions storage_type -- the weld is
# the `use base` alone, which is precisely why a storage_type-only rule
# missed it.
{
  package T::SLC::WeldedComponent;
  use base 'T::SLC::DriverComponent';
  sub connection {
    my ($self, @info) = @_;
    $self->register_storage_layer('T::SLC::Layer');
    return $self->next::method(@info);
  }
}

# A "layer" that is really a storage subclass with a constructor -- the shape
# DBIO::Storage::Composed's "Layer rules" forbid outright.
{
  package T::SLC::StorageSubclassLayer;
  use base 'DBIO::Storage::DBI';
  sub new { my $class = shift; return bless {}, $class }
}

# ---------------------------------------------------------------------------
# the legitimate shapes pass
# ---------------------------------------------------------------------------

storage_layer_contract_ok(
  'T::SLC::CleanComponent' => 'T::SLC::Layer',
  'component + layer: registers a layer, pins nothing, inherits no driver',
);

storage_layer_contract_ok(
  'T::SLC::InertComponent', undef,
  'inert marker component: no layer class to pass, still checkable',
);

# ...and without a test name at all, which is the one-liner an inert-marker
# extension repo actually writes.
storage_layer_contract_ok('T::SLC::InertComponent');

storage_layer_contract_ok(
  'T::SLC::BaselessComponent' => 'T::SLC::Layer',
  'a component with an empty @ISA is not a violation (the Age shape at HEAD)',
);

# ---------------------------------------------------------------------------
# dbio-postgresql-age -- welded by inheritance
# ---------------------------------------------------------------------------

{
  my @v = storage_layer_contract_violations('T::SLC::WeldedComponent');

  ok scalar @v,
    'dbio-postgresql-age shape (use base on a driver component) is caught';

  ok scalar( grep { /inherits the connect hook T::SLC::DriverComponent::connection/ } @v ),
    'diagnostic names the inherited connect hook and the driver component';

  ok scalar( grep { /dbio-postgresql-age/ } @v ),
    'diagnostic ties the finding to the incident it re-enacts';

  # The inherited driver hook pins storage_type through the composed MRO, so
  # the runtime probe sees the weld too. Two independent structural checks,
  # one root cause -- that redundancy is the point: neither check alone would
  # have covered both incidents.
  ok scalar( grep { /pins storage_type from its connect path/ } @v ),
    'the inherited pin is visible to the runtime probe as well';
}

# ---------------------------------------------------------------------------
# dbio-mysql-ev -- pinned by storage_type, clean inheritance
# ---------------------------------------------------------------------------

{
  my @v = storage_layer_contract_violations('T::SLC::PinningComponent');

  ok scalar @v, 'dbio-mysql-ev shape (connection() pinning storage_type) is caught';

  ok scalar( grep { /pins storage_type from its connect path/ } @v ),
    'diagnostic names storage_type pinning as the cause';

  ok scalar( grep { /\+T::SLC::PinningComponent::Storage/ } @v ),
    'diagnostic reports the value that was pinned';

  ok scalar( grep { /dbio-mysql-ev/ } @v ),
    'diagnostic ties the finding to the incident it re-enacts';

  # This one is invisible to the inheritance check: its @ISA is spotless.
  # If the storage_type probe were ever dropped, this assertion is what tells
  # the maintainer that dbio-mysql-ev went uncovered.
  ok !scalar( grep { /inherits/ } @v ),
    'the inheritance check alone would NOT have caught dbio-mysql-ev';
}

# ...and symmetrically, the storage_type probe alone is not what makes
# dbio-postgresql-age a finding: the welded component's own hook mentions
# storage_type nowhere.
{
  my @v = storage_layer_contract_violations('T::SLC::WeldedComponent');
  ok scalar( grep { /inherits the connect hook/ } @v ),
    'the two checks are independent mechanisms, not one check twice';
}

# ---------------------------------------------------------------------------
# layer rules (DBIO::Storage::Composed "Layer rules")
# ---------------------------------------------------------------------------

{
  my @v = storage_layer_contract_violations(
    'T::SLC::CleanComponent' => 'T::SLC::StorageSubclassLayer',
  );

  ok scalar( grep { /inherits the storage class DBIO::Storage::DBI/ } @v ),
    'a layer that use-bases a driver storage is caught';

  ok scalar( grep { /defines its own constructor \(new\)/ } @v ),
    'a layer that brings its own constructor is caught';

  ok scalar( grep { /Layer rules/ } @v ),
    'layer diagnostics point at the DBIO::Storage::Composed rules';
}

is_deeply
  [ storage_layer_contract_violations('T::SLC::CleanComponent', 'T::SLC::Layer') ],
  [],
  'the clean pair produces no violations at all';

# ---------------------------------------------------------------------------
# the ADR pointer is part of the contract, not decoration
# ---------------------------------------------------------------------------

{
  my @v = storage_layer_contract_violations('T::SLC::PinningComponent');
  ok scalar( grep { /_determine_driver/ } @v ),
    'diagnostic says who is supposed to make the decision instead';
}

# ---------------------------------------------------------------------------
# argument handling
# ---------------------------------------------------------------------------

eval { storage_layer_contract_violations(); 1 };
like $@, qr/requires a component class name/,
  'a missing component class is a loud error, not a silent pass';

eval { storage_layer_contract_violations('T::SLC::CleanComponent', {}); 1 };
like $@, qr/layer argument must be a class name/,
  'a non-class layer argument is a loud error';

done_testing;
