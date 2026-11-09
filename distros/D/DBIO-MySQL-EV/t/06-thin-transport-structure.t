use strict;
use warnings;
use Test::More;

# OFFLINE structural guard for the karr #19 thin-transport refactor (the MySQL
# twin of dbio-postgresql-ev #22). No EV::MariaDB, no real DB. This encodes the
# WHOLE POINT of the refactor as an assertable contract: DBIO::MySQL::EV::Storage
# must be a THIN transport over the core DBIO::Storage::Async machinery -- the
# shared CRUD / txn / sql_maker orchestration is INHERITED, only loop-/wire-
# specific seams + genuine MySQL value-add live here. If a future change
# reintroduces a parallel reimplementation of the async surface (the exact
# regression #19 removed), this test fails.

use DBIO::MySQL::EV::Storage;

my $EV   = 'DBIO::MySQL::EV::Storage';
my $BASE = 'DBIO::Storage::Async';

isa_ok $EV, $BASE, 'EV storage is a DBIO::Storage::Async';

# --- The shared Model-B machinery MUST be inherited, not redefined in EV ------
# Guard: the coderef the EV class resolves for each method is the SAME coderef as
# the base class -- i.e. EV does not shadow it with a parallel implementation.

sub resolves_to_base {
  my $method = shift;
  my $ev_cv   = $EV->can($method);
  my $base_cv = $BASE->can($method);
  return $ev_cv && $base_cv && $ev_cv == $base_cv;
}

for my $m (qw(
  select_async select_single_async update_async delete_async
  _run_crud _pool_runner _pinned_runner _seam_future
  _returning_columns
  txn_do_async pipeline sql_maker
  select select_single insert update delete txn_do
  _current_async_connect_info
  _strip_private_connect_attrs _access_broker_call_options
  _access_broker_call_attributes _access_broker_pool_size
  _takes_broker_connect_options
  connected in_txn disconnect schema debug
  listen unlisten notify listen_alive listen_reconnect
  _listen_dispatch _listen_lost _listen_error
)) {
  ok resolves_to_base($m),
    "$m is inherited from $BASE (no parallel reimplementation in EV)";
}

# --- The transport seams + genuine MySQL value-add MUST be defined in EV -------

sub defined_in_ev {
  my $method = shift;
  no strict 'refs';
  return defined &{"${EV}::$method"};
}

for my $m (qw(
  sql_maker_class _sql_maker_args _post_insert_sql
  _transform_sql _query_async _await_query_result _query_async_pinned
  _mysql_rollback _mysql_commit
  _run_pool_connect_statement
  _txn_context_class _txn_conn_accessor
  transport_capabilities future_class
  connect_info _async_broker_conninfo _normalize_async_connect_info
  _mysql_refuse_parameters_beside_broker
  _conninfo_hash pool _executor
  insert_async _run_crud_pinned _insert_returned_columns _auto_increment_column
  last_insert_id
  _listen_open _listen_close _listen_subscribe _listen_unsubscribe
  _listen_watch _listen_unwatch _listen_probe _listen_delay _notify_send
  deploy_notify_table
)) {
  ok defined_in_ev($m), "$m is implemented in EV (transport seam / MySQL value-add)";
}

# --- MySQL value-add: insert + LII overrides the RETURNING-shaped runner -------
# Unlike the PostgreSQL twin (which fully inherits insert_async / _run_crud_pinned
# / _insert_returned_columns), MySQL has no RETURNING clause, so these three MUST
# be overridden here -- prove they do NOT resolve to the base coderef.

ok !resolves_to_base('insert_async'),
  'insert_async is overridden in EV (INSERT + LAST_INSERT_ID, not the base RETURNING runner)';
ok !resolves_to_base('_run_crud_pinned'),
  '_run_crud_pinned is overridden in EV (insert branch runs LAST_INSERT_ID on the pinned conn)';
ok !resolves_to_base('_insert_returned_columns'),
  '_insert_returned_columns is overridden in EV (folds LII onto the auto_increment column)';
ok !resolves_to_base('_normalize_async_connect_info'),
  '_normalize_async_connect_info is overridden in EV (maps dbname -> database)';

# --- Removed parallel machinery must NOT come back ----------------------------

ok !defined_in_ev('_generate_sql'),
  '_generate_sql removed (base _run_crud + sql_maker produce the SQL)';
ok !defined_in_ev('_run_on_conn'),
  '_run_on_conn removed (base runners acquire/release around the query seams)';
ok !defined_in_ev('_query_on'),
  '_query_on removed (the query seams hand the statement to the executor; _await_query_result is only the dispatch core\'s _seam_future takes by name)';
ok !defined_in_ev('_debug_query'),
  '_debug_query is not defined here (the one trace rule is the core\'s, DBIO::Storage::Async::_debug_query, core ADR 0025; the QueryExecutor traces nothing)';
ok !defined_in_ev('sql_maker'),
  'sql_maker removed (inherited base builds it from sql_maker_class + _sql_maker_args)';
ok !defined_in_ev('select_async'),
  'select_async removed (inherited from base)';
ok !defined_in_ev('txn_do_async'),
  'txn_do_async removed (inherited base bracketing via the txn context seams)';
ok !defined_in_ev('pipeline'),
  'pipeline removed (EV::MariaDB pipelines automatically; no explicit-mode seam, capability not declared)';

# --- WP5: transport_capabilities: on_connect_replay + emulated listen/notify ---
# The karr #18 pool on_connect replay, plus listen and notify for the
# LISTEN/NOTIFY EMULATION over a notify table (karr k44).
#
# This assertion used to read "on_connect_replay only (no listen/notify/copy/
# pipeline)". For listen/notify that claim was RIGHT about the engine: MySQL
# and MariaDB have no native LISTEN/NOTIFY, and nothing here had one. It is
# replaced, not because it was wrong, but because the maintainer decided
# (2026-09-26, core ADR 0056 section 6, dbio-mysql ADR 0008) that both MySQL
# transports EMULATE the core listen contract and declare it. The rest of the
# old claim stands and is still asserted: MySQL has no COPY, and EV::MariaDB
# has no explicit pipeline-mode API to bracket (ADR 0009), so neither copy nor
# pipeline is declared.
#
# broker_connect_options (karr k59) joins the list. It is read by core, not by
# layers: it makes core hand this transport the connect options beside an
# AccessBroker, [ $broker, \%options ]. The claim "listen, notify and
# on_connect_replay, nothing else" is replaced on purpose: it was right while
# connect_info took a broker alone, and wrong to keep once it takes the options
# too -- without the declaration core refuses such a connection. The behaviour
# the declaration promises is claimed in
# t/30-access-broker-connect-options-mock.t; the split of those options and the
# pool-size rule are core's (asserted inherited, above), so the connect_info
# override cannot grow a reading of its own.

is_deeply
  [ sort $EV->transport_capabilities ],
  [ qw(broker_connect_options listen notify on_connect_replay) ],
  'transport_capabilities == on_connect_replay + listen + notify (emulated) + broker_connect_options';
ok !(grep { $_ eq 'copy' || $_ eq 'pipeline' } $EV->transport_capabilities),
  '... and still neither copy nor pipeline';

# --- SQLMaker seam wiring: the maker still emits the MySQL dialect -------------

my $storage = $EV->new(undef);
is $storage->sql_maker_class, 'DBIO::MySQL::SQLMaker', 'sql_maker_class seam';
is $storage->_post_insert_sql, '', '_post_insert_sql seam is empty (MySQL has no RETURNING)';
is $storage->_txn_context_class, 'DBIO::MySQL::EV::TransactionContext',
  '_txn_context_class points at the EV transaction context';
is $storage->_txn_conn_accessor, 'txn_conn',
  "_txn_conn_accessor is core's constructor key (karr k31; was the private 'mdb')";
isa_ok $storage->_txn_context_class, 'DBIO::Storage::Async::TransactionContext',
  'the EV txn context class';

my $sm = $storage->sql_maker;
isa_ok $sm, 'DBIO::MySQL::SQLMaker', 'sql_maker built via base from the seam';
is $sm->{quote_char}, '`', 'maker quotes identifiers with backticks';

# --- The '?' seam contract: maker emits '?', transport LEAVES IT ('?' native) -
# The core #70 contract is that _run_crud hands the transport RAW '?' SQL and the
# transport shapes it internally. For MySQL the shaping is IDENTITY -- '?' is the
# native placeholder, so _transform_sql must return the SQL UNCHANGED. This is
# the exact opposite of the PostgreSQL twin (which rewrites ? -> $N); if a
# dialect rewrite ever creeps in here, this test fails.

my ($raw) = $sm->select('artist', ['name'], { id => 1 });
like $raw, qr/\?/, 'sql_maker emits a ? placeholder (the seam-contract input)';
is $storage->_transform_sql($raw), $raw,
  '_transform_sql is identity: ? placeholders are left untouched (MySQL native)';
unlike $storage->_transform_sql($raw), qr/\$\d/,
  '_transform_sql never introduces positional $N placeholders (not PostgreSQL)';

done_testing;
