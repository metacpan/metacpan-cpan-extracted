# ABSTRACT: karr #70 WP1 -- DBIO::Schema->register_storage_layer + connection() composition
use strict;
use warnings;

use Test::More;

use DBIO::Schema;
use DBIO::Storage::Composed;

# --- two plain layer packages -------------------------------------------
{ package T::SL::LayerA; sub tag_a { 'a' } }
{ package T::SL::LayerB; sub tag_b { 'b' } }

# --- two independent schema classes -------------------------------------
{ package T::SL::Schema; use base 'DBIO::Schema'; }
{ package T::SL::Other;  use base 'DBIO::Schema'; }

# --- default + append + order -------------------------------------------
is_deeply(T::SL::Schema->storage_layers, [], 'storage_layers defaults to []');

T::SL::Schema->register_storage_layer('T::SL::LayerA');
T::SL::Schema->register_storage_layer('T::SL::LayerB');
is_deeply(T::SL::Schema->storage_layers,
  [ 'T::SL::LayerA', 'T::SL::LayerB' ],
  'register_storage_layer appends in registration order');

# --- dedup (connection() may run more than once) ------------------------
T::SL::Schema->register_storage_layer('T::SL::LayerA');
is_deeply(T::SL::Schema->storage_layers,
  [ 'T::SL::LayerA', 'T::SL::LayerB' ],
  'duplicate registration is a no-op, order preserved');

# --- CRITICAL: no leak through the shared inherited default arrayref ----
is_deeply(T::SL::Other->storage_layers, [],
  'a sibling schema class is unaffected (register did not mutate the shared arrayref)');
is_deeply(DBIO::Schema->storage_layers, [],
  'the parent DBIO::Schema is unaffected');

# --- register requires a class name -------------------------------------
eval { T::SL::Schema->register_storage_layer('') };
like $@, qr/requires a storage layer class name/,
  'register_storage_layer rejects an empty layer';

# --- connection() composes the registered layers over the base storage --
# connect(sub {}) is lazy: it builds and stores the storage but never
# connects (no driver determination, no DB), so this is fully offline.
my $schema  = T::SL::Schema->connect(sub {});
my $storage = $schema->storage;

isa_ok $storage, 'T::SL::LayerA',       'connected storage composed with layer A';
isa_ok $storage, 'T::SL::LayerB',       'connected storage composed with layer B';
isa_ok $storage, 'DBIO::Storage::DBI',  'composed over the generic base storage';
can_ok $storage, 'tag_a';
can_ok $storage, 'tag_b';

ok(DBIO::Storage::Composed->composition_of(ref $storage),
  'the storage class is a registered composition');
is_deeply([ DBIO::Storage::Composed->layers_of(ref $storage) ],
  [ 'T::SL::LayerA', 'T::SL::LayerB' ],
  'the composed storage records the registered layers, in order');

# --- a schema with no layers gets a plain, uncomposed storage -----------
my $plain = T::SL::Other->connect(sub {});
is ref($plain->storage), 'DBIO::Storage::DBI',
  'a schema with no registered layers gets the bare base storage (no composition)';

# --- register is callable on an instance too ----------------------------
{ package T::SL::LayerC; sub tag_c { 'c' } }
my $inst = T::SL::Other->connect(sub {});
$inst->register_storage_layer('T::SL::LayerC');
is_deeply($inst->storage_layers, [ 'T::SL::LayerC' ],
  'register_storage_layer works on an instance');
is_deeply(T::SL::Other->storage_layers, [],
  'the instance registration did not leak to the class');

done_testing;
