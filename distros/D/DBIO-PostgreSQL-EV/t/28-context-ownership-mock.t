use strict;
use warnings;
use Test::More;
use Test::Exception;

# OFFLINE mock. No EV::Pg pool is ever materialised and no server is touched:
# the whole test lives in the ownership-token bookkeeping, which happens before
# any connection is acquired. Building the embedded EV backend and setting its
# connect_info is connectionless (the pool is lazy), so this runs with no DB.
#
# WHY THIS FILE EXISTS (this repo k38, adopting core k196 / ADR 0045):
# with_context on a ResultSet/Row/ResultSetColumn now refuses a context that
# does not belong to the storage's current ownership generation. Core scopes
# ownership to an opaque per-backend/-pool token: DBIO::Storage::Async rotates
# it in new / connect_info / disconnect and mirrors it onto the concrete sync
# owner. This dist OVERRIDES connect_info and disconnect, and before k38 those
# overrides skipped the rotation -- so a context of an outgoing pool generation
# stayed accepted after the generation was torn down or reconfigured.
#
# The four scenarios below are the ticket's DONE list. Scenarios 1-3 (same
# backend accepted / foreign backend refused / composed EV storage is one
# ownership domain) already held on the UNFIXED code, because two distinct
# backend objects already have distinct new-minted tokens -- they are baseline,
# not the regression proof. Scenario 4 (generation rotation) is the actual
# proof of THIS fix: it is RED on the unfixed overrides (ctx_old wrongly stays
# accepted after disconnect / connect_info reconfigure) and GREEN once the
# overrides rotate like the base class.

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use Scalar::Util qw(refaddr);
use DBIO::Test;
use DBIO::PostgreSQL::Storage;

# Build a real sync PostgreSQL storage in { async => 'ev' } mode over a dbi:Pg:
# DSN, install it as the schema's storage (so result_source->storage -- the
# object with_context asserts against -- is this concrete sync owner), and
# materialise its embedded EV backend. Materialising the backend BEFORE probing
# ownership is deliberate: driver/transport resolution is lazy (it runs on first
# ->async), and sampling the intermediate state is exactly the trap the house
# rules warn about. Returns ($schema, $sync, $backend).
sub build_ev_storage {
  my (%arg) = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer($_) for @{ $arg{layers} || [] };

  my $sync = DBIO::PostgreSQL::Storage->new($schema);
  $sync->connect_info(
    [ 'dbi:Pg:dbname=dbio_mock;host=127.0.0.1', 'u', 'p', { async => 'ev' } ]
  );
  $schema->storage($sync);

  my $backend = $sync->async;   # lazy resolution happens here, connectionlessly
  return ($schema, $sync, $backend);
}

sub make_ctx {
  my ($backend, $conn) = @_;
  return $backend->_txn_context_class->new(
    storage  => $backend,
    txn_conn => $conn,
  );
}

# ===========================================================================
# Scenario 1: a context of the SAME EV backend is accepted by with_context on
# ResultSet, Row and ResultSetColumn. (Baseline -- holds pre-fix too.)
# ===========================================================================
{
  my ($schema, $sync, $backend) = build_ev_storage();
  isa_ok $backend, 'DBIO::PostgreSQL::EV::Storage',
    "{ async => 'ev' } resolved the EV transport";
  is refaddr($backend->_owner_storage), refaddr($sync),
    'the EV backend points back at its concrete sync owner';

  my $ctx = make_ctx($backend, 'CONN1');

  my $rs = $schema->resultset('Artist');
  my $bound;
  lives_ok { $bound = $rs->with_context($ctx) }
    'ResultSet::with_context accepts a context of the same EV backend';
  is refaddr($bound->_async_context), refaddr($ctx),
    'the accepted context is carried through unchanged';

  # A Row derived from the source, and a ResultSetColumn, take the same path.
  my $row = $schema->resultset('Artist')->new_result({ name => 'x' });
  lives_ok { $row->with_context($ctx) }
    'Row::with_context accepts a context of the same EV backend';
  lives_ok { $rs->get_column('name')->with_context($ctx) }
    'ResultSetColumn::with_context accepts a context of the same EV backend';
}

# ===========================================================================
# Scenario 2: a FOREIGN context (a different EV backend on a different schema)
# is refused, with the generation-mismatch message. (Baseline -- holds pre-fix.)
# ===========================================================================
{
  my ($schema_a, undef, $backend_a) = build_ev_storage();
  my ($schema_b, undef, $backend_b) = build_ev_storage();

  isnt refaddr($backend_a), refaddr($backend_b),
    'the two EV backends are distinct objects';

  my $ctx_b = make_ctx($backend_b, 'CONN_B');

  throws_ok { $schema_a->resultset('Artist')->with_context($ctx_b) }
    qr/does not belong to this storage generation/,
    'a foreign EV backend context is refused with a clear message';

  # A context-shaped object carrying no ownership evidence fails closed too.
  {
    package T::K38::Impostor;
    sub select_async { }   # enough to pass with_context's duck-type gate
  }
  throws_ok {
    $schema_a->resultset('Artist')->with_context(bless {}, 'T::K38::Impostor')
  } qr/ownership cannot be proven/,
    'a context without ownership evidence fails closed';
}

# ===========================================================================
# Scenario 3: a COMPOSED EV storage (an async layer mirrored over the EV
# transport, driven by a sync storage carrying the sync layer) is ONE ownership
# domain: same-owner context accepted, foreign refused. (Baseline -- holds
# pre-fix; proves the fix does not regress the composed case.)
# ===========================================================================
{
  # A synthetic composable extension: a plain sync layer plus its async mirror.
  # The mirror declares no required_transport_capabilities, so core treats it as
  # needing the default _query_async seam -- which the EV transport owns, so it
  # composes cleanly over EV.
  {
    package T::K38::Layer;         sub k38_layer_sync  { 1 }
    package T::K38::Layer::Async;  sub k38_layer_async { 1 }
  }

  my ($schema, $sync, $backend) = build_ev_storage(layers => ['T::K38::Layer']);

  ok $backend->isa('DBIO::PostgreSQL::EV::Storage'),
    'the composed backend still isa the EV transport';
  ok $backend->isa('T::K38::Layer::Async'),
    'the async layer was mirrored onto the EV transport';
  is refaddr($backend->_owner_storage), refaddr($sync),
    'the composed EV backend points at its concrete sync owner (one domain)';

  my $ctx = make_ctx($backend, 'CONN_C');
  lives_ok { $schema->resultset('Artist')->with_context($ctx) }
    'a context of the composed EV backend is accepted on its own schema';

  my ($schema_x, undef, $backend_x) = build_ev_storage();
  my $ctx_x = make_ctx($backend_x, 'CONN_X');
  throws_ok { $schema->resultset('Artist')->with_context($ctx_x) }
    qr/does not belong to this storage generation/,
    'a foreign context is refused by the composed EV storage';
}

# ===========================================================================
# Scenario 4: GENERATION ROTATION -- the actual regression proof for k38.
#
# A context minted from a backend generation must stop being accepted once that
# generation ends. This is RED on the unfixed overrides: EV::disconnect did not
# rotate, and EV::connect_info rotated only when a pool/LISTEN conn existed, so
# ctx_old survived the teardown/reconfigure and was still accepted. It is GREEN
# once the overrides rotate the ownership token like the base class.
# ===========================================================================

# 4a: rotation on disconnect.
{
  my ($schema, $sync, $backend) = build_ev_storage();

  my $ctx_old = make_ctx($backend, 'CONN_OLD');
  lives_ok { $schema->resultset('Artist')->with_context($ctx_old) }
    'before disconnect, the current-generation context is accepted';

  my $tok_before = refaddr($backend->_context_owner_token);
  $backend->disconnect;                       # ends this generation
  my $tok_after = refaddr($backend->_context_owner_token);

  isnt $tok_after, $tok_before,
    'disconnect rotates the ownership token to a new generation';

  # The mirror reached the concrete sync owner, so with_context (asserting on
  # result_source->storage == $sync) sees the NEW generation.
  is refaddr($sync->_async_context_owner_token),
     refaddr($backend->_context_owner_token),
    'the rotated token is mirrored onto the concrete sync owner';

  throws_ok { $schema->resultset('Artist')->with_context($ctx_old) }
    qr/does not belong to this storage generation/,
    'REGRESSION: a context of the outgoing generation is refused after disconnect';

  my $ctx_new = make_ctx($backend, 'CONN_NEW');
  lives_ok { $schema->resultset('Artist')->with_context($ctx_new) }
    'a context minted in the new generation is accepted after disconnect';
}

# 4b: rotation on connect_info reconfigure (no pool / no LISTEN conn present).
{
  my ($schema, $sync, $backend) = build_ev_storage();

  my $ctx_old = make_ctx($backend, 'CONN_OLD2');
  lives_ok { $schema->resultset('Artist')->with_context($ctx_old) }
    'before reconfigure, the current-generation context is accepted';

  my $tok_before = refaddr($backend->_context_owner_token);
  $backend->connect_info(
    [ 'dbi:Pg:dbname=dbio_mock2;host=127.0.0.1', 'u', 'p', { async => 'ev' } ]
  );
  my $tok_after = refaddr($backend->_context_owner_token);

  isnt $tok_after, $tok_before,
    'connect_info reconfigure rotates the ownership token even with no pool';
  is refaddr($sync->_async_context_owner_token),
     refaddr($backend->_context_owner_token),
    'the reconfigure-rotated token is mirrored onto the concrete sync owner';

  throws_ok { $schema->resultset('Artist')->with_context($ctx_old) }
    qr/does not belong to this storage generation/,
    'REGRESSION: a context of the pre-reconfigure generation is refused';

  my $ctx_new = make_ctx($backend, 'CONN_NEW2');
  lives_ok { $schema->resultset('Artist')->with_context($ctx_new) }
    'a context minted after reconfigure is accepted';
}

done_testing;
