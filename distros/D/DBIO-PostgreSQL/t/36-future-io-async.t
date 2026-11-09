use strict;
use warnings;
use Test::More;
use Test::Exception;

# ADR 0030/0031 (core karr k65 + dbio-postgresql karr k25): the future_io async
# mode resolves its transport adapter by CONVENTION -- ref($storage) . '::Async'
# -- off the concrete PostgreSQL driver storage. This dist ships that adapter,
# DBIO::PostgreSQL::Storage::Async, the first REAL future_io transport (over
# DBD::Pg's pg_async binding).
#
# These are pure class/registry/introspection assertions: no event loop, no
# real database, no Future::IO dep. The live roundtrip lives in
# t/37-future-io-live.t (gated on DBIO_TEST_PG_*).

use DBIO::Storage::DBI;
use DBIO::PostgreSQL::Storage;

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends -- a minimal install may not have it. Load the adapter
# (which pulls the base) defensively so this offline suite skips cleanly instead
# of dying at compile time when dbio-async is absent.
BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# -----------------------------------------------------------------------
# 1. The adapter is a concrete future_io transport
# -----------------------------------------------------------------------
isa_ok 'DBIO::PostgreSQL::Storage::Async', 'DBIO::Async::Storage',
  'adapter is a Future::IO transport (DBIO::Async::Storage)';
isa_ok 'DBIO::PostgreSQL::Storage::Async', 'DBIO::Storage::Async',
  'adapter is a DBIO::Storage::Async (Model-B orchestration base)';

# -----------------------------------------------------------------------
# 2. future_io is resolved by CONVENTION, not by an explicit registration
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage->_resolve_async_mode_class('future_io', exclude => 'DBIO::Storage::DBI'),
  undef,
  'no explicit per-driver future_io registration -- the class is resolved by convention',
);

# -----------------------------------------------------------------------
# 3. The core resolver resolves future_io to the adapter off a PG storage.
#    Drive the REAL resolver end-to-end (offline: a bare reblessed storage,
#    no connect -- connect_info(undef) does not touch the database).
# -----------------------------------------------------------------------
{
  my $storage = bless {}, 'DBIO::PostgreSQL::Storage';
  $storage->_async_mode('future_io');
  delete $storage->{_async_storage_obj};

  my $async = $storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
    'connect(..., { async => future_io }) resolves the convention adapter';
  is $storage->async, $async,
    'the same adapter is cached and feeds the *_async CRUD dispatch';
}

# -----------------------------------------------------------------------
# 4. Every DB-specific transport seam is overridden -- none left croaking
#    "Subclass must override" in the abstract base. Comparing the resolved
#    coderef against the base's croaking one proves the override concretely.
#
#    _txn_context_class / _txn_conn_accessor used to be in this list. They do
#    not belong here any more: since dbio-async k13 the Future::IO base ANSWERS
#    both (with this transport's own TransactionContext under the key
#    txn_conn) instead of croaking, so "the coderef differs from the base's"
#    stopped standing for "the adapter answers correctly" and started meaning
#    only "the adapter re-declares a value it already inherits". The property
#    those two carry -- the adapter names the right transaction context -- is
#    asserted on the VALUE in section 4b, which holds whether the answer is
#    inherited or defined here.
# -----------------------------------------------------------------------
{
  # Seams the dbio-async Future::IO base (DBIO::Async::Storage) leaves croaking:
  my @async_base_seams = qw(
    _submit_query _collect_result _normalize_conninfo
    _create_pool_connection _shutdown_pool_connection
    _conn_ready _conn_fileno
  );
  # Seams the Model-B base (DBIO::Storage::Async) leaves croaking:
  my @orch_base_seams = qw( sql_maker_class _transform_sql _post_insert_sql );

  for my $seam (@async_base_seams) {
    my $ours = DBIO::PostgreSQL::Storage::Async->can($seam);
    my $base = DBIO::Async::Storage->can($seam);
    ok $ours && $base && $ours != $base,
      "seam $seam is overridden (not the croaking DBIO::Async::Storage default)";
  }
  for my $seam (@orch_base_seams) {
    my $ours = DBIO::PostgreSQL::Storage::Async->can($seam);
    my $base = DBIO::Storage::Async->can($seam);
    ok $ours && $base && $ours != $base,
      "seam $seam is overridden (not the croaking DBIO::Storage::Async default)";
  }
}

# -----------------------------------------------------------------------
# 4b. The transaction context the adapter ANSWERS with
#
#     txn_do_async reads these two to build the context it hands the caller's
#     coderef, so the value is the whole contract -- where it is declared is
#     not. Since dbio-async k13 both come from the Future::IO base's own
#     defaults and this adapter defines neither (karr k68); before that it
#     repeated them verbatim. Either way these assertions hold, and they go
#     red the moment the answer itself changes.
# -----------------------------------------------------------------------
is( DBIO::PostgreSQL::Storage::Async->_txn_context_class, 'DBIO::Async::TransactionContext',
  '_txn_context_class is the future_io transaction context' );
is( DBIO::PostgreSQL::Storage::Async->_txn_conn_accessor, 'txn_conn',
  '_txn_conn_accessor matches the generic pinned-connection key' );

# -----------------------------------------------------------------------
# 5. SQL-shaping seams produce the PostgreSQL shapes
# -----------------------------------------------------------------------
is( DBIO::PostgreSQL::Storage::Async->sql_maker_class, 'DBIO::PostgreSQL::SQLMaker',
  'sql_maker_class is the PostgreSQL SQLMaker' );
is( DBIO::PostgreSQL::Storage::Async->_post_insert_sql, ' RETURNING *',
  '_post_insert_sql is RETURNING * (returned-columns hashref, ADR 0031)' );

# -----------------------------------------------------------------------
# 6. _transform_sql: '?' -> positional '$N', honouring the PG subtleties
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage::Async->_transform_sql(
    q{SELECT "artistid", "name" FROM "artist" WHERE "name" = ? AND "rank" = ?}
  ),
  q{SELECT "artistid", "name" FROM "artist" WHERE "name" = $1 AND "rank" = $2},
  'placeholders rewritten left-to-right to $1, $2',
);
is(
  DBIO::PostgreSQL::Storage::Async->_transform_sql(q{WHERE "data" @\? ?::jsonpath}),
  q{WHERE "data" @? $1::jsonpath},
  'the jsonpath operator, written @\? as the maker writes it, reaches the server as @?; the placeholder is $1',
);
is(
  DBIO::PostgreSQL::Storage::Async->_transform_sql(q{WHERE "data" @? ?::jsonpath}),
  q{WHERE "data" @$1 $2::jsonpath},
  'a bare ? behind @ is a placeholder, as at the dbh',
);
is(
  DBIO::PostgreSQL::Storage::Async->_transform_sql(q{WHERE "x" = 'lit ? eral' AND "y" = ?}),
  q{WHERE "x" = 'lit ? eral' AND "y" = $1},
  'a ? inside a string literal is left alone',
);

done_testing;
