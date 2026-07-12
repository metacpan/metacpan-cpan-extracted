use strict;
use warnings;
use Test::More;

# OFFLINE structural guard for the karr #22 thin-transport refactor. No EV::Pg,
# no real DB. This encodes the WHOLE POINT of the refactor as an assertable
# contract: DBIO::PostgreSQL::EV::Storage must be a THIN transport over the core
# DBIO::Storage::Async machinery -- the shared CRUD / txn / pipeline / sql_maker
# orchestration is INHERITED, only loop-/wire-specific seams + value-add live
# here. If a future change reintroduces a parallel reimplementation of the async
# surface (the exact regression #22 removed), this test fails.

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
)) {
  ok resolves_to_base($m),
    "$m is inherited from $BASE (no parallel reimplementation in EV)";
}

# --- The transport seams + value-add MUST be defined in EV --------------------

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
  _txn_context_class _txn_conn_accessor
  transport_capabilities future_class
  connect_info _conninfo_string _async_broker_conninfo pool disconnect
  listen unlisten notify copy_in deploy_async
)) {
  ok defined_in_ev($m), "$m is implemented in EV (transport seam / value-add)";
}

# --- Removed parallel machinery must NOT come back ----------------------------

ok !$EV->can('_to_positional'),
  '_to_positional removed (renamed to the base _transform_sql seam)';
ok !defined_in_ev('_generate_sql'),
  '_generate_sql removed (base _run_crud + sql_maker produce the SQL)';

# --- WP5: transport_capabilities is exactly what WP3/WP4 make real ------------

is_deeply
  [ sort $EV->transport_capabilities ],
  [ sort qw(on_connect_replay listen notify copy pipeline) ],
  'transport_capabilities == on_connect_replay, listen, notify, copy, pipeline';

# --- SQLMaker seam wiring: the maker still emits the PostgreSQL dialect --------

my $storage = $EV->new(undef);
is $storage->sql_maker_class, 'DBIO::PostgreSQL::SQLMaker', 'sql_maker_class seam';
is $storage->_post_insert_sql, ' RETURNING *', '_post_insert_sql seam is RETURNING *';
is $storage->_txn_context_class, 'DBIO::PostgreSQL::EV::TransactionContext',
  '_txn_context_class points at the EV transaction context';
is $storage->_txn_conn_accessor, 'pg', '_txn_conn_accessor is the EV pinned-conn key';

my $sm = $storage->sql_maker;
isa_ok $sm, 'DBIO::PostgreSQL::SQLMaker', 'sql_maker built via base from the seam';
is $sm->{quote_char}, '"', 'maker quotes identifiers with double quotes';

# --- The '?' seam contract: maker emits '?', transport shapes to '$N' ---------
# The core #70 contract is that _run_crud hands the transport RAW '?' SQL and the
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
