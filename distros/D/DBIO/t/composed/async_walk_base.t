# ABSTRACT: karr #70 follow-up -- async transport resolution walks the composition
# BASE (the driver), never the sync layers stacked on top of a composed storage.
use strict;
use warnings;

use Test::More;
use mro;

use DBIO::Test;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;

# ---------------------------------------------------------------------------
# The bug this guards against (latent -- no shipping consumer yet, first hit by
# the AGE/PostGIS future_io+layer case):
#
# #70 WP1/WP2 compose SYNC storage layers INTO the storage class, so after
# driver rebless a composed instance's class is e.g.
#   DBIO::Storage::Composed::<Layer>__<DriverStorage>
# and mro::get_linear_isa(ref $self) now CONTAINS the layer package, MORE
# specific than the driver storage. A sync layer's async mirror <Layer>::Async
# (the WP2 convention target) is a PLAIN async layer package, NOT a
# DBIO::Storage::Async transport. The future_io transport walk in _async_storage
# used to iterate mro::get_linear_isa(ref $self) and would therefore find and
# load <Layer>::Async BEFORE reaching the driver's real ::Async, then croak
# "loaded but is not a DBIO::Storage::Async".
#
# The fix: async transport/mode resolution is a property of the DRIVER, so both
# walks resolve against the composition BASE (_async_resolution_class), which
# strips the layers back out of the linearisation. This is the integration proof
# that the WP2 async mirror and the walk fix work TOGETHER.
# ---------------------------------------------------------------------------

# --- a fake driver storage + its REAL async transport --------------------
{
  package T::WF::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub driver_marker { 'driver' }
}
{
  package T::WF::DriverStorage::Async;      # the driver's real future_io transport
  use base 'DBIO::Storage::Async';
  use mro 'c3';
}

# --- a SYNC layer L + its PLAIN async mixin (NOT a transport) -------------
{ package T::WF::L;        sub layer_marker { 'sync' } }
{ package T::WF::L::Async; sub async_marker { 'async' } }   # NOT a DBIO::Storage::Async

# Preconditions that make the old walk croak and the new walk correct.
ok( T::WF::DriverStorage::Async->isa('DBIO::Storage::Async'),
  'sanity: the driver transport IS a DBIO::Storage::Async' );
ok( !T::WF::L::Async->isa('DBIO::Storage::Async'),
  'sanity: the sync layer mixin L::Async is NOT a DBIO::Storage::Async '
  . '(probing it as a transport is exactly what used to croak)' );

# Register the fake driver against a fake DBD name so a synthetic dsn reblesses
# to it without ever connecting (dsn-only connect info, DBI-style regex parse).
DBIO::Storage::DBI->register_driver('FakeWFDrv' => 'T::WF::DriverStorage');

# ===========================================================================
# Direct unit: _async_resolution_class returns the composition BASE for a
# composed instance, and ref($self) for a plain one (and the class for a
# class-method call -- the ref($self) || $self fallback).
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema;

  my $composed_class =
    DBIO::Storage::Composed->compose('T::WF::DriverStorage', ['T::WF::L']);
  my $composed = $composed_class->new($schema);
  is $composed->_async_resolution_class, 'T::WF::DriverStorage',
    '_async_resolution_class returns the composition base for a composed instance';

  my $plain = T::WF::DriverStorage->new($schema);
  is $plain->_async_resolution_class, 'T::WF::DriverStorage',
    '_async_resolution_class returns ref($self) for a non-composed instance';

  is( DBIO::Storage::DBI->_async_resolution_class, 'DBIO::Storage::DBI',
    '_async_resolution_class as a class method keeps the ref($self)||$self fallback' );

  # The layer really IS more-specific than the driver in the composed MRO --
  # this is the precondition the walk fix has to survive.
  my @isa = @{ mro::get_linear_isa($composed_class) };
  ok +(grep { $_ eq 'T::WF::L' }              @isa), 'composed MRO contains the sync layer';
  ok +(grep { $_ eq 'T::WF::DriverStorage' }  @isa), 'composed MRO contains the driver storage';
}

# ===========================================================================
# Integration: connect a COMPOSED schema with { async => 'future_io' } and drive
# the full rebless-through-connect. Resolution must NOT croak on L::Async, must
# land on the DRIVER's real transport, and the async mirror must compose L::Async
# ON TOP of that transport.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer('T::WF::L');

  # A composed GENERIC storage (base == DBIO::Storage::DBI), bound to the schema,
  # in future_io mode. connect_info's dsn drives the driver rebless; { async }
  # sets the mode. No connection is ever opened.
  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::Storage::DBI', ['T::WF::L']);
  my $storage = $composed_class->new($schema);
  $storage->connect_info([ 'dbi:FakeWFDrv:', '', '', { async => 'future_io' } ]);

  # THE call that used to croak on T::WF::L::Async before reaching the driver.
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'future_io resolution does NOT croak on the sync layer mixin L::Async'
    or diag "died with: $err";

  # The sync storage reblessed onto the driver, keeping its layer (bug precondition).
  isa_ok $storage, 'T::WF::DriverStorage', 'sync storage reblessed onto the driver';
  isa_ok $storage, 'T::WF::L',             'sync storage kept its layer through rebless';
  ok +(grep { $_ eq 'T::WF::L' } @{ mro::get_linear_isa(ref $storage) }),
    'the sync layer sits in the reblessed storage MRO (more-specific than the driver)';

  # The resolved transport is the DRIVER's real ::Async, not the layer mixin.
  ok $async, 'an async backend was resolved';
  isa_ok $async, 'T::WF::DriverStorage::Async',
    'the resolved transport is the DRIVER\'s ::Async (walk found the driver, not the layer)';
  isa_ok $async, 'DBIO::Storage::Async', '... which is a real DBIO::Storage::Async';

  # The WP2 async mirror composed L::Async ON TOP of the transport.
  isa_ok $async, 'T::WF::L::Async',
    'the async mirror composed the layer\'s L::Async on top of the transport';
  can_ok $async, 'async_marker';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::WF::L::Async' ],
    'exactly the one async mirror layer composed over the driver transport';
}

done_testing;
