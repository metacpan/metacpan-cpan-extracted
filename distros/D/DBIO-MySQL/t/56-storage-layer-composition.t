use strict;
use warnings;
use Test::More;
use mro;

# Storage-layer composition, driver side (core karr #70; this dist is a
# reference MySQL transport). A driver extension is a plain storage LAYER, not a
# storage_type subclass: registered via DBIO::Schema::register_storage_layer, it
# composes (C3) OVER the driver storage for sync, and its async mirror
# (<Layer>::Async) composes OVER the future_io transport when a schema connects
# { async => 'future_io' }. MySQL ships no such extensions today, but the
# mechanism is core-provided and the reference driver must honour it.
#
# These are pure class/composition/introspection assertions -- no event loop, no
# real database. The end-to-end live proof lives in t/57-*-live.t (gated on
# DBIO_TEST_MYSQL_*). Modelled on the PostgreSQL reference t/38 and core
# t/composed/async_walk_base.t.

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::MySQL::Storage;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends. Load the MySQL adapter (which pulls the base) defensively
# so this offline suite skips cleanly instead of dying when dbio-async is absent.
BEGIN {
  eval { require DBIO::MySQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- a synthetic extension: a plain sync storage layer + its plain async mirror
{ package T::MyExt::Storage;        sub my_ext_marker       { 'sync-layer' } }
{ package T::MyExt::Storage::Async; sub my_ext_async_marker { 'async-layer' } }

# Preconditions: the layers are PLAIN packages -- neither a storage subclass nor
# a transport. Probing the async mirror as a transport is exactly what the walk
# must NOT do (it resolves the transport off the driver, not the layers).
ok !T::MyExt::Storage->isa('DBIO::Storage::DBI'),
  'sanity: the sync layer is a plain package, not a DBIO::Storage::DBI subclass';
ok !T::MyExt::Storage::Async->isa('DBIO::Storage::Async'),
  'sanity: the async mirror is a plain package, not a DBIO::Storage::Async transport';

# ===========================================================================
# 1. SYNC composition: the layer composes OVER the real MySQL driver storage.
#    The composed class isa BOTH, and the layer method is callable.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::MySQL::Storage', ['T::MyExt::Storage']);

  ok $composed_class->isa('DBIO::MySQL::Storage'),
    'composed sync class isa the MySQL driver storage (the base)';
  ok $composed_class->isa('T::MyExt::Storage'),
    'composed sync class isa the extension layer';
  can_ok $composed_class, 'my_ext_marker';

  my $storage = $composed_class->new($schema);
  isa_ok $storage, 'DBIO::MySQL::Storage', 'composed instance';
  isa_ok $storage, 'T::MyExt::Storage', 'composed instance carries the layer';
  is $storage->my_ext_marker, 'sync-layer',
    'the layer method is callable on the composed sync storage';

  is_deeply [ DBIO::Storage::Composed->layers_of($composed_class) ],
    [ 'T::MyExt::Storage' ],
    'layers_of records exactly the one composed layer';
}

# ===========================================================================
# 2. ASYNC composition: a layered schema connected { async => 'future_io' }
#    resolves the MySQL future_io transport off the DRIVER (not the layer) and
#    composes the layer's ::Async mirror ON TOP of that transport.
#    Structural only -- driver rebless is a dsn-string parse, no DB is opened.
# ===========================================================================
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_storage_layer('T::MyExt::Storage');

  # A composed GENERIC storage (base == DBIO::Storage::DBI) bound to the schema,
  # in future_io mode. The dsn drives the driver rebless to DBIO::MySQL::Storage
  # (DBI-style parse of 'mysql'); { async } sets the mode. No connection is ever
  # opened.
  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::Storage::DBI', ['T::MyExt::Storage']);
  my $storage = $composed_class->new($schema);
  $storage->connect_info(
    [ 'dbi:mysql:dbname=dbio_offline_compose', '', '', { async => 'future_io' } ]
  );

  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'future_io resolution over a layered MySQL storage does not croak'
    or diag "died with: $err";

  # The sync storage reblessed onto the MySQL driver, keeping its layer through
  # the rebless (the layer is more-specific than the driver in the composed MRO).
  isa_ok $storage, 'DBIO::MySQL::Storage',
    'sync storage reblessed onto the MySQL driver';
  isa_ok $storage, 'T::MyExt::Storage',
    'sync storage kept its layer through the driver rebless';
  ok +(grep { $_ eq 'T::MyExt::Storage' } @{ mro::get_linear_isa(ref $storage) }),
    'the layer sits in the reblessed storage MRO';

  # The resolved transport is the MySQL future_io adapter -- found off the
  # driver, NOT the layer's plain ::Async mirror.
  ok $async, 'an async backend was resolved';
  isa_ok $async, 'DBIO::MySQL::Storage::Async',
    'the resolved transport is the MySQL future_io adapter (walk hit the driver)';
  isa_ok $async, 'DBIO::Async::Storage', '... which is a real Future::IO transport';

  # The async mirror composed the layer's ::Async ON TOP of the transport.
  isa_ok $async, 'T::MyExt::Storage::Async',
    'the async mirror composed the layer ::Async on top of the transport';
  can_ok $async, 'my_ext_async_marker';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::MyExt::Storage::Async' ],
    'exactly the one async mirror layer composed over the MySQL future_io transport';
}

# ===========================================================================
# 3. MariaDB flavour: a dbi:MariaDB: dsn reblesses to the MariaDB driver storage
#    and the walk resolves its MariaDB future_io adapter, still composing the
#    layer's async mirror on top.
# ===========================================================================
{
  eval { require DBIO::MySQL::Storage::MariaDB::Async; 1 }
    or plan skip_all =>
      'DBIO::MySQL::Storage::MariaDB::Async unavailable';

  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_storage_layer('T::MyExt::Storage');

  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::Storage::DBI', ['T::MyExt::Storage']);
  my $storage = $composed_class->new($schema);
  $storage->connect_info(
    [ 'dbi:MariaDB:dbname=dbio_offline_compose', '', '', { async => 'future_io' } ]
  );

  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'future_io resolution over a layered MariaDB storage does not croak'
    or diag "died with: $err";

  isa_ok $storage, 'DBIO::MySQL::Storage::MariaDB',
    'sync storage reblessed onto the MariaDB driver';
  isa_ok $async, 'DBIO::MySQL::Storage::MariaDB::Async',
    'the resolved transport is the MariaDB future_io adapter (convention off the driver)';
  isa_ok $async, 'DBIO::MySQL::Storage::Async',
    '... which is the same MySQL transport (subclass)';
  isa_ok $async, 'T::MyExt::Storage::Async',
    'the async mirror composed the layer ::Async on top of the MariaDB transport';
}

done_testing;
