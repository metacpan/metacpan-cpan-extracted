use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr);

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::TransactionContext;

# OFFLINE driver-side adoption of the async context OWNERSHIP model
# (core karr k196 / ADR 0045 section 4) for the EV transport (karr k37).
#
# Core scopes every async context to one backend/pool GENERATION with an
# opaque token: DBIO::Storage::Async mints a fresh \$opaque per generation, the
# concrete SYNC storage (the OWNER) mirrors the current backend's token, and
# with_context / ORM dispatch prove ownership by REFERENCE IDENTITY of that
# token before binding a resultset to a pinned context. Nothing but reference
# identity counts -- class, DSN and schema equality prove no ownership.
#
# The EV backend inherits the whole token machinery from DBIO::Storage::Async
# (new / disconnect rotate; _new/_rotate/_context_owner_token) and its context
# is a thin subclass of core's DBIO::Storage::Async::TransactionContext (so it
# inherits the construction-time token snapshot and the owner assertion). The
# one EV-specific seam is the connect_info override, exercised by case (d).
#
# This pins the driver-visible consequences DB-free (no event loop, no socket):
#   (a) a SAME-generation context is ACCEPTED by with_context;
#   (b) a FOREIGN backend's context, and a context-shaped object carrying no
#       token, are REFUSED with the two distinct core messages;
#   (c) the sync layer + its EV backend are ONE ownership domain -- the token
#       is mirrored onto the concrete OWNER object;
#   (d) a truthy connect_info setter rotates the backend token EVEN when no
#       pool has been materialised (ADR 0045 section 4: reconfiguration opens a
#       new generation "including reconfiguration before a pool has been
#       materialised").
#
# The EV backend is resolved DB-free through the sync storage's _async_storage
# (which forces driver determination off the DSN and wires owner + token), and
# contexts are built directly via
# _txn_context_class->new(storage => $backend, txn_conn => 'CONN') -- exactly
# as core's own t/resultset/with_context.t builds them for its fake transport.

# A real, composed MySQL schema: load_components('MySQL') makes the sync layer
# DBIO::MySQL::Storage over DBIO::Storage::DBI, and { async => 'ev' } selects
# the native EV transport. connect is lazy -- it touches no database here.
{
  package DBIO::MySQL::EV::Test::OwnershipSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw(Artist)] });
}

# A context-shaped object that implements select_async (so it passes
# with_context's shape check) but carries no ownership token, so it must fail
# closed at the ownership assertion.
{
  package DBIO::MySQL::EV::Test::TokenlessContext;
  sub new { bless {}, shift }
  sub select_async { }
}

# Build one connected schema and force DB-free resolution of its EV backend.
# HOUSE RULE (composition seams): driver resolution is lazy -- assert the
# concrete driver/backend only AFTER connect + _async_storage, never on the
# generic intermediate storage. Returns ($schema, $sync_storage, $ev_backend).
sub wired_ev {
  my $schema = DBIO::MySQL::EV::Test::OwnershipSchema->connect(
    'dbi:mysql:database=t;host=localhost', 'u', 'p', { async => 'ev' },
  );
  my $storage = $schema->storage;
  # Forces _determine_driver off the DSN and wires the owner back-ref + the
  # mirrored generation token -- all without a live connection.
  my $backend = $storage->_async_storage;
  return ($schema, $storage, $backend);
}

# ---------------------------------------------------------------------------
# (c) ONE ownership domain: the token is mirrored onto the CONCRETE owner.
# Assert the driver only after connect (composition-seam house rule).
# ---------------------------------------------------------------------------
my ($schema_a, $storage_a, $backend_a) = wired_ev();

isa_ok $backend_a, 'DBIO::MySQL::EV::Storage',
  'ev backend resolved DB-free through the sync storage';
isa_ok $backend_a->_owner_storage, 'DBIO::MySQL::Storage',
  'owner is the concrete driver storage (resolved AFTER connect, not the generic base)';
is refaddr($storage_a->_async_context_owner_token),
   refaddr($backend_a->_context_owner_token),
  'sync owner mirrors the backend generation token -- sync layer + EV backend are ONE domain';

# ---------------------------------------------------------------------------
# (a) a SAME-generation context is ACCEPTED by with_context.
# ---------------------------------------------------------------------------
my $ctx_a = $backend_a->_txn_context_class->new(
  storage  => $backend_a,
  txn_conn => 'CONN_A',
);
isa_ok $ctx_a, 'DBIO::MySQL::EV::TransactionContext';
is refaddr($ctx_a->_context_owner_token), refaddr($backend_a->_context_owner_token),
  'the context snapshots its backend generation token at construction';

my $rs_a = $schema_a->resultset('Artist');
my $bound;
lives_ok { $bound = $rs_a->with_context($ctx_a) }
  'a same-generation context is accepted by with_context';
isa_ok $bound, 'DBIO::ResultSet', 'with_context returns a bound resultset clone';
is refaddr($bound->_async_context), refaddr($ctx_a),
  'the bound clone carries exactly the accepted context';

# ---------------------------------------------------------------------------
# (b) a FOREIGN backend's context, and a tokenless external object, are
# REFUSED -- with the two distinct core messages.
# ---------------------------------------------------------------------------
my ($schema_b, $storage_b, $backend_b) = wired_ev();
isnt refaddr($backend_b->_context_owner_token), refaddr($backend_a->_context_owner_token),
  'a second schema/backend is a DIFFERENT ownership generation';

my $ctx_b = $backend_b->_txn_context_class->new(
  storage  => $backend_b,
  txn_conn => 'CONN_B',
);
throws_ok { $rs_a->with_context($ctx_b) }
  qr/does not belong to this storage generation/,
  'a foreign backend context is refused with the generation-mismatch message';

throws_ok {
  $rs_a->with_context(DBIO::MySQL::EV::Test::TokenlessContext->new)
} qr/ownership cannot be proven/,
  'a context-shaped object without an ownership token is refused (fails closed)';

# ---------------------------------------------------------------------------
# (d) connect_info rotates the token WITHOUT a materialised pool -- the
# concrete gap this ticket closes. ADR 0045 section 4: a truthy connect_info
# setter opens a new ownership generation, "including reconfiguration before a
# pool has been materialised". The EV connect_info override rotates via the
# inherited disconnect only when a pool already exists; the no-pool branch must
# rotate explicitly (mirroring the base connect_info), or a context from the
# OLD generation survives a reconfiguration and would keep dispatching onto a
# pool later built from DIFFERENT credentials.
#
# The refaddr assertion below is RED before the fix (the no-pool branch does
# not rotate) and GREEN after.
# ---------------------------------------------------------------------------
{
  my ($schema, $storage, $backend) = wired_ev();
  ok !$backend->{pool},
    'witness backend starts without a materialised async pool';

  my $old_ctx = $backend->_txn_context_class->new(
    storage  => $backend,
    txn_conn => 'PRE_RECONFIG_CONN',
  );
  my $old_token = $backend->_context_owner_token;

  $backend->connect_info([ { host => 'localhost', database => 't2' }, {} ]);

  ok !$backend->{pool},
    'connect_info rotates without materialising a pool';
  isnt refaddr($backend->_context_owner_token), refaddr($old_token),
    'a truthy connect_info setter rotates the backend generation token even with no pool';
  is refaddr($storage->_async_context_owner_token),
     refaddr($backend->_context_owner_token),
    'the rotated token is mirrored to the concrete owner';

  # Consequence: a context from the pre-reconfiguration generation is stale.
  throws_ok {
    $schema->resultset('Artist')->with_context($old_ctx)
  } qr/does not belong to this storage generation/,
    'a pre-reconfiguration context is refused after connect_info';

  # A context from the new generation is accepted.
  my $new_ctx = $backend->_txn_context_class->new(
    storage  => $backend,
    txn_conn => 'POST_RECONFIG_CONN',
  );
  lives_ok {
    $schema->resultset('Artist')->with_context($new_ctx)
  } 'a context from the new generation is accepted after connect_info';
}

done_testing;
