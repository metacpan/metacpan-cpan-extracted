use strict;
use warnings;
use Test::More;

# OFFLINE structural guard for the karr k22 thin-transport refactor. No EV::Pg,
# no real DB. This encodes the WHOLE POINT of the refactor as an assertable
# contract: DBIO::PostgreSQL::EV::Storage must be a THIN transport over the core
# DBIO::Storage::Async machinery -- the shared CRUD / txn / pipeline / sql_maker
# orchestration is INHERITED, only loop-/wire-specific seams + value-add live
# here. If a future change reintroduces a parallel reimplementation of the async
# surface (the exact regression k22 removed), this test fails.

use DBIO::PostgreSQL::EV::Storage;

my $EV = 'DBIO::PostgreSQL::EV::Storage';
my $BASE = 'DBIO::Storage::Async';

isa_ok $EV, $BASE, 'EV storage is a DBIO::Storage::Async';

# --- The shared Model-B machinery MUST be inherited, not redefined in EV ------
# Guard: the coderef the EV class resolves for each method is the SAME coderef as
# the base class -- i.e. EV does not shadow it with a parallel implementation.

sub resolves_to_base {
  my $method = shift;
  no strict 'refs';
  my $ev_cv   = $EV->can($method);
  my $base_cv = $BASE->can($method);
  return $ev_cv && $base_cv && $ev_cv == $base_cv;
}

for my $m (qw(
  select_async select_single_async insert_async update_async delete_async
  _run_crud _pool_runner _pinned_runner _run_crud_pinned
  _insert_returned_columns _returning_columns
  txn_do_async pipeline sql_maker
  select select_single insert update delete txn_do
  _normalize_async_connect_info _current_async_connect_info
  _strip_private_connect_attrs _access_broker_call_options
  _access_broker_call_attributes _access_broker_pool_size
  _takes_broker_connect_options
  deploy _execute_ddl_async _drop_statements_for
  _use_transactional_ddl
  listen unlisten notify listen_alive listen_reconnect
  _listen_dispatch _listen_lost _listen_error disconnect
)) {
  ok resolves_to_base($m),
    "$m is inherited from $BASE (no parallel reimplementation in EV)";
}

# karr k43 REPLACED a claim here rather than preserving it. listen / unlisten /
# notify and disconnect used to be asserted as EV-defined value-add. Core ADR
# 0056 made LISTEN/NOTIFY a core async contract -- the public methods, the hooks
# and the healing machinery are core's -- and an EV override of any of them
# bypasses that machinery, which is exactly why the old EV LISTEN connection
# never reconnected. disconnect was overridden only to finish that connection;
# core's ends listening itself. So they now MUST resolve to core (above), and
# the value-add claim moves to the listen seams (below).

# --- The transport seams + value-add MUST be defined in EV --------------------
# karr k96 moved deploy_async and _install_ddl here from the inherited list: the
# transport asks the server for the control-file schemas of the declared
# extensions before the DDL is built, a thin layer that still runs core's own
# deploy_async (SUPER) and DDL runner, which stay inherited.

sub defined_in_ev {
  my $method = shift;
  no strict 'refs';
  return defined &{"${EV}::$method"};
}

for my $m (qw(
  sql_maker_class _sql_maker_args _post_insert_sql
  _transform_sql _query_async _query_async_pinned
  _run_pool_connect_statement
  _pipeline_enter _pipeline_sync _pipeline_exit
  _txn_context_class _txn_conn_accessor _txn_commit_rolled_back _txn_inner_future _ddl_class
  transport_capabilities future_class
  connect_info _conninfo_string _async_broker_conninfo pool
  _listen_open _listen_close _listen_subscribe _listen_unsubscribe
  _listen_watch _listen_unwatch _listen_probe _listen_delay _notify_send
  copy_in deploy_async _install_ddl
)) {
  ok defined_in_ev($m), "$m is implemented in EV (transport seam / value-add)";
}

# --- Removed parallel machinery must NOT come back ----------------------------

ok !$EV->can('_to_positional'),
  '_to_positional removed (renamed to the base _transform_sql seam)';
ok !defined_in_ev('_generate_sql'),
  '_generate_sql removed (base _run_crud + sql_maker produce the SQL)';

# --- WP5: transport_capabilities is exactly what WP3/WP4 make real ------------
# broker_connect_options (karr k60) is read by core, not by layers: it makes
# core hand this transport the connect options beside an AccessBroker. The
# behaviour it promises is claimed in t/51-access-broker-connect-options-mock.t;
# the split of those options and the pool-size rule are core's (inherited,
# above), so the connect_info override cannot grow a reading of its own.

is_deeply
  [ sort $EV->transport_capabilities ],
  [ sort qw(on_connect_replay listen notify copy pipeline broker_connect_options) ],
  'transport_capabilities == on_connect_replay, listen, notify, copy, pipeline, broker_connect_options';

# --- SQLMaker seam wiring: the maker still emits the PostgreSQL dialect --------

my $storage = $EV->new(undef);
is $storage->sql_maker_class, 'DBIO::PostgreSQL::SQLMaker', 'sql_maker_class seam';
is $storage->_post_insert_sql, ' RETURNING *', '_post_insert_sql seam is RETURNING *';
is $storage->_txn_context_class, 'DBIO::PostgreSQL::EV::TransactionContext',
  '_txn_context_class points at the EV transaction context';
# karr k32 REPLACED this claim rather than preserving it. The value of this
# seam IS the constructor key -- core's txn_do_async builds the context as
# $class->new(storage => ..., $accessor => $conn) -- and the constructor is now
# core's DBIO::Storage::Async::TransactionContext, which dies without
# 'txn_conn'. A green 'pg' after k32 would have proved the seam never moved
# while the constructor underneath it was swapped out. The driver-native name
# survives as the txn_pg READ accessor, pinned in t/transaction-context.t.
is $storage->_txn_conn_accessor, 'txn_conn',
  '_txn_conn_accessor names core\'s constructor key';
is $storage->_ddl_class, 'DBIO::PostgreSQL::DDL',
  '_ddl_class seam resolves the same DDL generator as the sync deploy path (karr k25)';

my $sm = $storage->sql_maker;
isa_ok $sm, 'DBIO::PostgreSQL::SQLMaker', 'sql_maker built via base from the seam';
is $sm->{quote_char}, '"', 'maker quotes identifiers with double quotes';

# --- The '?' seam contract: maker emits '?', transport shapes to '$N' ---------
# The core k70 contract is that _run_crud hands the transport RAW '?' SQL and the
# transport shapes it internally. Prove _transform_sql is that shaping and is a
# no-op on already-'$N' SQL (passthrough intact).

my ($raw) = $sm->select('artist', ['name'], { id => 1 });
like $raw, qr/\?/, 'sql_maker emits a ? placeholder (the seam-contract input)';
my $shaped = $storage->_transform_sql($raw);
unlike $shaped, qr/(?<!\@)\?/, '_transform_sql rewrites ? to positional $N';
like $shaped, qr/\$1\b/, '... numbered $1';
is $storage->_transform_sql('SELECT * FROM t WHERE id = $1'),
   'SELECT * FROM t WHERE id = $1',
   '$N SQL passes through _transform_sql unchanged (idempotent)';

done_testing;
