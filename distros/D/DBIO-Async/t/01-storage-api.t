use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# --- API surface check ---
# Storage has the composed methods (does not croak until a hook is called)

my $storage = DBIO::Async::Storage->new(undef);

# --- future_class ---

is($storage->future_class, 'Future',
  'future_class is Future');

can_ok $storage, qw(
  select_async select_single_async insert_async update_async delete_async
  txn_do_async pipeline
  select select_single insert update delete txn_do
  sql_maker pool connect_info connected disconnect
  _run_crud _run_crud_pinned _pool_runner _pinned_runner
  _query_async _query_async_pinned
  _await_conn_ready _await_query_result
  _submit_query _collect_result _transform_sql _post_insert_sql
  _normalize_conninfo _create_pool_connection _shutdown_pool_connection
  _conn_ready _conn_fileno
  _txn_context_class _txn_conn_accessor
  _pipeline_enter _pipeline_sync _pipeline_exit
  sql_maker_class
  future_class
);

# --- Seam hooks croak ---

throws_ok { $storage->sql_maker_class }
  qr/Subclass must override sql_maker_class/,
  'sql_maker_class croaks';

throws_ok { $storage->_submit_query(undef, 'SELECT 1', []) }
  qr/Subclass must override _submit_query/,
  '_submit_query croaks';

throws_ok { $storage->_collect_result(undef, 'SELECT 1', []) }
  qr/Subclass must override _collect_result/,
  '_collect_result croaks';

throws_ok { $storage->_transform_sql('SELECT 1') }
  qr/Subclass must override _transform_sql/,
  '_transform_sql croaks';

throws_ok { $storage->_post_insert_sql }
  qr/Subclass must override _post_insert_sql/,
  '_post_insert_sql croaks';

throws_ok { $storage->_normalize_conninfo([]) }
  qr/Subclass must override _normalize_conninfo/,
  '_normalize_conninfo croaks';

throws_ok { $storage->_create_pool_connection('dummy') }
  qr/Subclass must override _create_pool_connection/,
  '_create_pool_connection croaks';

throws_ok { $storage->_shutdown_pool_connection(undef) }
  qr/Subclass must override _shutdown_pool_connection/,
  '_shutdown_pool_connection croaks';

throws_ok { $storage->_conn_ready(undef) }
  qr/Subclass must override _conn_ready/,
  '_conn_ready croaks';

throws_ok { $storage->_txn_context_class }
  qr/Subclass must override _txn_context_class/,
  '_txn_context_class croaks';

throws_ok { $storage->_txn_conn_accessor }
  qr/Subclass must override _txn_conn_accessor/,
  '_txn_conn_accessor croaks';

throws_ok { $storage->_pipeline_enter(undef) }
  qr/Subclass must override _pipeline_enter/,
  '_pipeline_enter croaks';

throws_ok { $storage->_pipeline_sync(undef) }
  qr/Subclass must override _pipeline_sync/,
  '_pipeline_sync croaks';

throws_ok { $storage->_pipeline_exit(undef) }
  qr/Subclass must override _pipeline_exit/,
  '_pipeline_exit croaks';

# --- in_txn on Storage is false ---

ok !$storage->in_txn, 'storage in_txn is false';

# --- TransactionContext API ---

can_ok 'DBIO::Async::TransactionContext', qw(
  new storage txn_conn pool in_txn
  _query_async
  select_async select_single_async insert_async update_async delete_async
  select select_single insert update delete
  sql_maker debug pipeline txn_do_async
);

done_testing;
