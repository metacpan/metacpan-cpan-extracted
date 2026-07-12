use strict;
use warnings;
use Test::More;
use mro;

# Storage-layer composition, driver side (core karr #70; this dist is the
# reference transport). A PostgreSQL extension is a plain storage LAYER, not a
# storage_type subclass: registered via DBIO::Schema::register_storage_layer, it
# composes (C3) OVER the driver storage for sync, and its async mirror
# (<Layer>::Async) composes OVER the future_io transport when a schema connects
# { async => 'future_io' }.
#
# These are pure class/composition/introspection assertions -- no event loop, no
# real database. The end-to-end live proof lives in t/39-*-live.t (gated on
# DBIO_TEST_PG_*). Modelled on core t/composed/async_walk_base.t.

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends. Load the PG adapter (which pulls the base) defensively so
# this offline suite skips cleanly instead of dying when dbio-async is absent.
BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- a synthetic extension: a plain sync storage layer + its plain async mirror
{ package T::PGExt::Storage;        sub pg_ext_marker       { 'sync-layer' } }
{ package T::PGExt::Storage::Async; sub pg_ext_async_marker { 'async-layer' } }

# Preconditions: the layers are PLAIN packages -- neither a storage subclass nor
# a transport. Probing the async mirror as a transport is exactly what the walk
# must NOT do (it resolves the transport off the driver, not the layers).
ok !T::PGExt::Storage->isa('DBIO::Storage::DBI'),
  'sanity: the sync layer is a plain package, not a DBIO::Storage::DBI subclass';
ok !T::PGExt::Storage::Async->isa('DBIO::Storage::Async'),
  'sanity: the async mirror is a plain package, not a DBIO::Storage::Async transport';

# ===========================================================================
# 1. SYNC composition: the layer composes OVER the real PG driver storage.
#    The composed class isa BOTH, and the layer method is callable.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::PostgreSQL::Storage', ['T::PGExt::Storage']);

  ok $composed_class->isa('DBIO::PostgreSQL::Storage'),
    'composed sync class isa the PostgreSQL driver storage (the base)';
  ok $composed_class->isa('T::PGExt::Storage'),
    'composed sync class isa the extension layer';
  can_ok $composed_class, 'pg_ext_marker';

  my $storage = $composed_class->new($schema);
  isa_ok $storage, 'DBIO::PostgreSQL::Storage', 'composed instance';
  isa_ok $storage, 'T::PGExt::Storage', 'composed instance carries the layer';
  is $storage->pg_ext_marker, 'sync-layer',
    'the layer method is callable on the composed sync storage';

  is_deeply [ DBIO::Storage::Composed->layers_of($composed_class) ],
    [ 'T::PGExt::Storage' ],
    'layers_of records exactly the one composed layer';
}

# ===========================================================================
# 2. ASYNC composition: a layered schema connected { async => 'future_io' }
#    resolves the PG future_io transport off the DRIVER (not the layer) and
#    composes the layer's ::Async mirror ON TOP of that transport.
#    Structural only -- driver rebless is a dsn-string parse, no DB is opened.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_storage_layer('T::PGExt::Storage');

  # A composed GENERIC storage (base == DBIO::Storage::DBI) bound to the schema,
  # in future_io mode. The dsn drives the driver rebless to
  # DBIO::PostgreSQL::Storage (DBI-style parse of 'Pg'); { async } sets the mode.
  # No connection is ever opened.
  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::Storage::DBI', ['T::PGExt::Storage']);
  my $storage = $composed_class->new($schema);
  $storage->connect_info(
    [ 'dbi:Pg:dbname=dbio_offline_compose', '', '', { async => 'future_io' } ]
  );

  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'future_io resolution over a layered PG storage does not croak'
    or diag "died with: $err";

  # The sync storage reblessed onto the PG driver, keeping its layer through the
  # rebless (the layer is more-specific than the driver in the composed MRO).
  isa_ok $storage, 'DBIO::PostgreSQL::Storage',
    'sync storage reblessed onto the PostgreSQL driver';
  isa_ok $storage, 'T::PGExt::Storage',
    'sync storage kept its layer through the driver rebless';
  ok +(grep { $_ eq 'T::PGExt::Storage' } @{ mro::get_linear_isa(ref $storage) }),
    'the layer sits in the reblessed storage MRO';

  # The resolved transport is the PG future_io adapter -- found off the driver,
  # NOT the layer's plain ::Async mirror.
  ok $async, 'an async backend was resolved';
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
    'the resolved transport is the PostgreSQL future_io adapter (walk hit the driver)';
  isa_ok $async, 'DBIO::Async::Storage', '... which is a real Future::IO transport';

  # The async mirror composed the layer's ::Async ON TOP of the transport.
  isa_ok $async, 'T::PGExt::Storage::Async',
    'the async mirror composed the layer ::Async on top of the transport';
  can_ok $async, 'pg_ext_async_marker';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::PGExt::Storage::Async' ],
    'exactly the one async mirror layer composed over the PG future_io transport';
}

done_testing;
