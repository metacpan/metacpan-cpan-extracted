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
  _run_crud _pool_runner _pinned_runner
  _returning_columns
  txn_do_async pipeline sql_maker
  select select_single insert update delete txn_do
  _current_async_connect_info
  connected in_txn disconnect schema debug
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
  _transform_sql _query_async _query_async_pinned
  _run_pool_connect_statement
  _txn_context_class _txn_conn_accessor
  transport_capabilities future_class
  connect_info _async_broker_conninfo _normalize_async_connect_info
  _conninfo_hash pool _executor
  insert_async _run_crud_pinned _insert_returned_columns _auto_increment_column
  last_insert_id
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
  '_query_on removed (the query seams call the executor directly)';
ok !defined_in_ev('_debug_query'),
  '_debug_query removed (the QueryExecutor is the single debug point)';
ok !defined_in_ev('sql_maker'),
  'sql_maker removed (inherited base builds it from sql_maker_class + _sql_maker_args)';
ok !defined_in_ev('select_async'),
  'select_async removed (inherited from base)';
ok !defined_in_ev('txn_do_async'),
  'txn_do_async removed (inherited base bracketing via the txn context seams)';
ok !defined_in_ev('pipeline'),
  'pipeline removed (EV::MariaDB pipelines automatically; no explicit-mode seam, capability not declared)';

# --- WP5: transport_capabilities is exactly on_connect_replay -----------------
# MySQL has no LISTEN/NOTIFY, no COPY, and no explicit pipeline-mode API, so the
# ONLY real capability is the karr #18 pool on_connect replay.

is_deeply
  [ sort $EV->transport_capabilities ],
  [ qw(on_connect_replay) ],
  'transport_capabilities == on_connect_replay only (no listen/notify/copy/pipeline)';

# --- SQLMaker seam wiring: the maker still emits the MySQL dialect -------------

my $storage = $EV->new(undef);
is $storage->sql_maker_class, 'DBIO::MySQL::SQLMaker', 'sql_maker_class seam';
is $storage->_post_insert_sql, '', '_post_insert_sql seam is empty (MySQL has no RETURNING)';
is $storage->_txn_context_class, 'DBIO::MySQL::EV::TransactionContext',
  '_txn_context_class points at the EV transaction context';
is $storage->_txn_conn_accessor, 'mdb', '_txn_conn_accessor is the EV pinned-conn key';

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
