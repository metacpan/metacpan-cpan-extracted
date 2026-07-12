use strict;
use warnings;
use Test::More;
use mro;

# WP4c (karr #6) -- the maintainer's KEY requirement: the async mode is
# per-INSTANCE (ADR 0030), never baked onto the schema class. ONE Age+PostGIS
# schema CLASS opens TWO connections in two different async modes; each instance
# resolves its OWN distinct composed async backend:
#
#   * future_io -> Age async layer composed over DBIO::PostgreSQL::Storage::Async
#   * ev        -> Age async layer composed over DBIO::PostgreSQL::EV::Storage
#
# The floating Age async layer rides BOTH transports, unchanged; PostGIS (a
# sync-only layer, no ::Async sibling) is absent from BOTH async backends. No live
# DB: this drives the REAL resolver far enough to get each backend CLASS (dsn is a
# string parse). EV and dbio-async are develop/recommends deps -- skip cleanly if
# either (or PostGIS) is missing.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all => 'future_io transport (DBIO::Async / DBD::Pg) not installed';
  eval { require DBIO::PostgreSQL::EV; require DBIO::PostgreSQL::EV::Storage; 1 }
    or plan skip_all => 'DBIO::PostgreSQL::EV (ev transport) not installed';
  eval { require DBIO::PostgreSQL::PostGIS; require DBIO::PostgreSQL::PostGIS::Storage; 1 }
    or plan skip_all => 'DBIO::PostgreSQL::PostGIS not installed';
}

use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Age::Storage;
use DBIO::PostgreSQL::Age::Storage::Async;

my $AGE_ASYNC = 'DBIO::PostgreSQL::Age::Storage::Async';
my $FIO_TRANSPORT = 'DBIO::PostgreSQL::Storage::Async';
my $EV_TRANSPORT  = 'DBIO::PostgreSQL::EV::Storage';
my $GIS_SYNC  = 'DBIO::PostgreSQL::PostGIS::Storage';

# ONE schema class carrying BOTH extension layers.
{
  package T::DualSchema;
  use base qw( DBIO::PostgreSQL::Age DBIO::PostgreSQL::PostGIS DBIO::Schema );
  use mro 'c3';
}

# Two connections from the SAME class, differing ONLY in async mode. Offline:
# connect() is lazy and ->async is a dsn-string rebless + class resolution; no
# database is contacted.
my $dsn = 'dbi:Pg:dbname=dbio_offline_dualmode';
my $fio_schema = T::DualSchema->connect($dsn, '', '', { async => 'future_io' });
my $ev_schema  = T::DualSchema->connect($dsn, '', '', { async => 'ev' });

# Sanity: both instances registered the same two sync layers on the same class.
is_deeply [ @{ $fio_schema->storage_layers } ],
  [ 'DBIO::PostgreSQL::Age::Storage', $GIS_SYNC ],
  'future_io instance carries the Age + PostGIS sync layers';
is_deeply [ @{ $ev_schema->storage_layers } ],
  [ 'DBIO::PostgreSQL::Age::Storage', $GIS_SYNC ],
  'ev instance carries the same Age + PostGIS sync layers (same class)';

my $fio_async = $fio_schema->storage->async;
my $ev_async  = $ev_schema->storage->async;

# ---------------------------------------------------------------------------
# future_io instance: Age async layer OVER the future_io transport.
# ---------------------------------------------------------------------------
isa_ok $fio_async, $FIO_TRANSPORT,
  'future_io instance backend isa the future_io transport';
isa_ok $fio_async, $AGE_ASYNC,
  'future_io instance backend carries the Age async layer';
ok !$fio_async->isa($EV_TRANSPORT),
  'future_io instance backend is NOT the ev transport';
is_deeply [ DBIO::Storage::Composed->layers_of(ref $fio_async) ], [ $AGE_ASYNC ],
  'future_io backend composed exactly the Age async layer (PostGIS absent -- no ::Async)';
can_ok $fio_async, 'cypher_async';

# ---------------------------------------------------------------------------
# ev instance: the SAME Age async layer OVER the ev transport.
# ---------------------------------------------------------------------------
isa_ok $ev_async, $EV_TRANSPORT,
  'ev instance backend isa the ev transport';
isa_ok $ev_async, $AGE_ASYNC,
  'ev instance backend carries the SAME Age async layer';
ok !$ev_async->isa($FIO_TRANSPORT),
  'ev instance backend is NOT the future_io transport';
is_deeply [ DBIO::Storage::Composed->layers_of(ref $ev_async) ], [ $AGE_ASYNC ],
  'ev backend composed exactly the Age async layer (PostGIS absent -- no ::Async)';
can_ok $ev_async, 'cypher_async';

# ---------------------------------------------------------------------------
# The mode is per-INSTANCE: two distinct composed backend classes from one class.
# ---------------------------------------------------------------------------
isnt ref($fio_async), ref($ev_async),
  'the two instances resolved DISTINCT composed backend classes -- mode is per-instance';

# ---------------------------------------------------------------------------
# PostGIS is sync-only: its layer never appears in EITHER async backend.
# ---------------------------------------------------------------------------
ok !$fio_async->isa($GIS_SYNC), 'PostGIS sync layer absent from the future_io backend';
ok !$ev_async->isa($GIS_SYNC),  'PostGIS sync layer absent from the ev backend';
ok !$fio_async->can('ensure_postgis'),
  'PostGIS storage surface (ensure_postgis) is not on the future_io async backend';
ok !$ev_async->can('ensure_postgis'),
  'PostGIS storage surface (ensure_postgis) is not on the ev async backend';

# ...yet the SYNC storage of BOTH instances still carries PostGIS (it is a
# sync-only layer), proving the async omission is deliberate, not a loss.
isa_ok $fio_schema->storage, $GIS_SYNC, 'future_io sync storage still carries PostGIS';
isa_ok $ev_schema->storage,  $GIS_SYNC, 'ev sync storage still carries PostGIS';

done_testing;
