use strict;
use warnings;
use Test::More;
use mro;

# karr #8 -- REGRESSION GUARD for the driver of a schema with the AGE layer, and
# for the LAZY driver determination of its composed storage.
#
# The AGE component is an extension, not a driver: it registers a storage layer
# and leaves storage_type alone (ADR 0032 section 7, house rule). It never
# determines the driver -- the SCHEMA declares it (core ADR 0067):
#
#   * a schema that loads ONLY the AGE component declares no driver and is
#     refused at connect, before any storage is built. Were the component to pin
#     the PostgreSQL storage, that schema would connect -- the composition seam
#     karr #8 broke once already.
#   * a schema that declares PostgreSQL (use DBIO 'Schema', -pg) gets the AGE
#     layer composed over DBIO::PostgreSQL::Storage from connect() on. What stays
#     LAZY is the determination: the first dbh access runs _determine_driver,
#     which lets the declared driver adapt to its access path (core ADR 0059)
#     and recomposes the same layers over the adapted class. Both sides of that
#     transition are nailed down here, so they are not rediscovered as a "bug" in
#     a live run.
#
# Offline by construction: the determination reads the DBD from the DSN string;
# no database is ever opened, and the test asserts that too.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage; 1 }
    or plan skip_all => 'DBIO::PostgreSQL not installed';
}

use DBIO ();
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age;
use DBIO::PostgreSQL::Age::Storage;

my $AGE_LAYER = 'DBIO::PostgreSQL::Age::Storage';
my $PG_BASE   = 'DBIO::PostgreSQL::Storage';
my $DSN       = 'dbi:Pg:dbname=dbio_offline_lazy_driver';

# ===========================================================================
# 1. THE EXTENSION IS NO DRIVER: a schema loading ONLY the AGE component.
# ===========================================================================
{
  package T::AgeOnlySchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::Age');
}
SKIP: {
  skip 'core without ADR 0067 (no DBIO->driver_for): a schema without a '
     . 'driver is not refused there', 4
    unless DBIO->can('driver_for');

  my $ok  = eval { T::AgeOnlySchema->connect($DSN, '', ''); 1 };
  my $err = $@;
  ok !$ok, 'a schema with the AGE component and no driver is refused at connect';
  like "$err", qr/Schema class T::AgeOnlySchema declares no driver/,
    'the refusal names the schema class and that it declares no driver';
  like "$err", qr/generic DBIO::Storage::DBI/,
    'the AGE component left the storage class generic: it declared nothing';
  like "$err", qr/use DBIO 'Schema', -<driver>/,
    'the refusal names the driver shortcut as the way out';
}

# ===========================================================================
# 2. A schema that declares PostgreSQL and loads the AGE layer.
# ===========================================================================
{
  package T::AgePgSchema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL::Age');
}

my $schema  = T::AgePgSchema->connect($DSN, '', '');
my $storage = $schema->storage;

is_deeply [ @{ $schema->storage_layers } ], [ $AGE_LAYER ],
  'the AGE component registered exactly its storage layer, and nothing else';

# ---------------------------------------------------------------------------
# 2a. BEFORE determination: the declared driver, not yet determined.
# ---------------------------------------------------------------------------
{
  my $composition = DBIO::Storage::Composed->composition_of(ref $storage);
  ok $composition, 'the freshly connected storage is a composed class';
  is $composition->{base}, $PG_BASE,
    'the composition base is the declared PostgreSQL driver storage from connect() on';

  isa_ok $storage, $AGE_LAYER, 'the undetermined storage';
  isa_ok $storage, $PG_BASE,   'the undetermined storage';

  ok !$storage->_driver_determined,
    'connect() does not determine the driver (determination is lazy -- this is correct, not a bug)';
  ok !defined $storage->_declared_storage_class,
    '... so the declared driver has not adapted to its access path yet';
}

# ===========================================================================
# 3. Determine the driver. This is what the first dbh access does internally;
#    calling it directly keeps the test offline.
# ===========================================================================
$storage->_determine_driver;

# ---------------------------------------------------------------------------
# 3a. AFTER determination: same layer, still the declared driver underneath.
# ---------------------------------------------------------------------------
{
  ok $storage->_driver_determined, 'the driver is determined now';
  is $storage->_declared_storage_class, $PG_BASE,
    'the determination went the declared-driver way, for PostgreSQL -- no guess from the DSN';

  my $composition = DBIO::Storage::Composed->composition_of(ref $storage);
  ok $composition, 'the determined storage is still a composed class';
  is $composition->{base}, $PG_BASE,
    'the composition base is still the PostgreSQL driver storage (dbi:Pg: needs no adaptation)';

  isa_ok $storage, $PG_BASE,   'the determined storage';
  isa_ok $storage, $AGE_LAYER, 'the determined storage (layer survived the determination)';

  is_deeply [ DBIO::Storage::Composed->layers_of(ref $storage) ], [ $AGE_LAYER ],
    'layers_of is unchanged by the determination';

  can_ok $storage, qw( cypher create_graph drop_graph );
}

ok !$storage->connected,
  'no database was opened for any of this (the determination reads the DSN string)';

done_testing;
