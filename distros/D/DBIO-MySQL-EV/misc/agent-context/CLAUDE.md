# CLAUDE.md — DBIO::MySQL::EV

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main
agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (async Storage, Pool, QueryExecutor, types) to
this repo's `dbio-worker-mysql-ev` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-mysql-ev` (default), `dbio-release-manager`,
`karr-coordinator`.

## Overview

The native `ev` async transport for MySQL/MariaDB (core ADR 0030 / 0031): an
EV::MariaDB backend for DBIO. No DBI, no DBD on the pooled connections -- it
speaks MariaDB's C client library directly. The working reference is the skill
`dbio-mysql-ev`; decisions are in `docs/adr/`.

## Namespace

- `DBIO::MySQL::EV` -- inert marker component: no methods, no `connection()` hook, pins no `storage_type` (ADR 0032 §7, karr k14)
- `DBIO::MySQL::EV::Storage` -- the transport, a `DBIO::Storage::Async` subclass; the Model-B orchestration is inherited
- `DBIO::MySQL::EV::Pool` -- EV::MariaDB connection pool, a `DBIO::Storage::PoolBase` subclass (ADR 0003)
- `DBIO::MySQL::EV::QueryExecutor` -- wire seam: EV::MariaDB `query` vs prepare/execute
- `DBIO::MySQL::EV::Future` -- the transport's `future_class`; its `await` runs the EV loop
- `DBIO::MySQL::EV::TransactionContext` -- pinned connection handed to a `txn_do_async` coderef; thin subclass of core's context
- `DBIO::MySQL::EV::ConnectInfo` -- `dbi_to_conninfo`: DBI DSN -> EV::MariaDB named parameters
- `DBIO::MySQL::EV::TestHarness` -- installable live-test harness; thin subclass of core's `DBIO::Test::AsyncHarness`

## Key Architecture

- Async is a per-connection mode: `connect($dsn, $user, $pass, { async => 'ev' })` on a schema that loads the `MySQL` driver component. The `ev` mode is registered by `DBIO::MySQL::Storage` (dist `dbio-mysql`), not here; `load_components('MySQL::EV')` changes nothing
- Uses EV::MariaDB (MariaDB Connector/C XS wrapper), NOT DBI/DBD::mysql. A DBI DSN is translated to EV::MariaDB named parameters (`dbname` -> `database`); of the DBI attributes only `pool_size` is read (default 5), the rest is dropped. Known DBD DSN keys (`mysql_socket`, `mysql_ssl_ca_file`, ... and the `mariadb_` ones), in the DSN and among the attributes, are translated; `mysql_enable_utf8mb4`/`mysql_enable_utf8` (DBD::mysql only) become `charset` utf8mb4/utf8 plus `utf8 => 1`; a `mysql_*`/`mariadb_*` attribute EV::MariaDB has no parameter for (`mysql_server_prepare`, ...) is refused, named, never dropped (karr k80); the one exception is `mysql_auto_reconnect`/`mariadb_auto_reconnect` with a false value (0, empty), which asks for nothing and passes (a true one is refused); CLIENT_FOUND_ROWS is on for every handle like the DBDs (`found_rows => 1`, off with `mysql_client_found_rows=0`, `Pool::_mysql_new_handle`); an unknown DSN key or a lowercase non-DBI attribute (`charset`, ...) is refused, never dropped (karr k64, k80); the positional DSN `dbi:mysql:app:host:port` is read; `$user`/`$pass` beat `user=`/`password=` in the DSN; the single-hash form `{ dsn, user, password, ... }` is read (karr k79); a `dbi:` DSN as `dbname` of a hash is refused
- All async methods return a `DBIO::MySQL::EV::Future` (a `Future`)
- Sync methods (`select`, `insert`, `txn_do`, ...) are the async sibling plus `->get`, which runs the EV loop (ADR 0001). A Future settles from an idle watcher of the loop, not inside the EV::MariaDB callback (karr k51), so a blocking `->get` also works inside a `then` of the transport's Futures and in a `txn_do` coderef, `$ctx->select` without binds included (the k48 refusal is gone). One wait that cannot end still dies with `Blocking wait refused: ...` instead of hanging: a call queued for a pooled connection while the running `then` chains/coderefs hold all of them (karr k53, e.g. `$storage->select` in a `txn_do` coderef with a pool of one). Plain queries a coderef issues at once are no longer sent as one batch: the first goes out, the next ones wait for its answer (karr k51)
- Transactions pin one pooled connection per `txn_do_async`; the coderef gets the `TransactionContext` (ADR 0002)
- AccessBroker: `connect($broker, { async => 'ev', pool_size => N })`. The broker is asked again for every pooled connection and for every open of the listen connection; nothing of its answer is stored (ADR 0006, karr k59, k62)
- Refused rather than connected without: a broker hash answer whose `dbname` is a whole DSN (karr k63), a connection parameter beside a broker (`charset`, `host`, ... -- karr k78; beside it only `pool_size` and DBI attributes). No connection message quotes a password: everything goes through `DBIO::Util::mask_connect_secrets` (karr k76)
- A pinned `ROLLBACK` waits behind the statements in flight on its connection (EV::MariaDB refuses a query during a prepare/execute), and a `ROLLBACK` or a `COMMIT` that fails retires the connection: a connection with an open transaction never goes back to the pool (karr k74, ADR 0002 amendment); the wait is bounded by the storage attribute `rollback_wait_timeout` (seconds, default 30: then the ROLLBACK is not sent, the connection is retired, the transaction fails with a reason), and every statement on a pinned connection queues behind a prepare/execute in flight, not only the ROLLBACK (karr k81)
- A connection whose session is gone is retired, never handed out again: asked about before an idle one is borrowed (karr k58) and after a failed statement (karr k55); the check is local, `DBIO::MySQL::EV::Pool::_mysql_connection_gone` (ADR 0010)
- Boundary of that gone-check (decided, not built; maintainer 2026-10-24, karr k75): a hand-written `PREPARE h FROM 'CALL p()'` + `EXECUTE h` sent through `query` can, over plain TCP, make the check retire the healthy idle connection once (one reconnect, no error). A `CALL` the transport builds is not affected (karr k84)
- The session is reset when a borrow ends (core ADR 0079, ADR 0011, karr k100): `Storage::_reset_pool_connection` sends `COM_RESET_CONNECTION` (`QueryExecutor::reset_connection`), then sets the connection's character set and collation again (`SET NAMES <charset> COLLATE <collation>`, the two names read once per connection after the connect actions of its spawn, checked for `[A-Za-z0-9_]`), then replays the connect actions (`_setup_pool_connection`); the pool hands the connection on only after all three answered, and a failure or a missed `reset_timeout` retires it. No opt-out. Every borrow has the session of the new connection, character set and collation included
- Statement trace is the core's (`DBIO::Storage::Async::_debug_query`, core ADR 0025, karr core k402): `Storage::_mysql_execute` and the pinned ROLLBACK/COMMIT/reset call it once per statement and hand `query_end` to the Future's `on_ready`; the QueryExecutor traces nothing. `_query_async`/`_query_async_pinned` take the optional `$bind_attrs`; wire binds stay bare values
- An error text names keys, columns and options, never a value (core ADR 0075): MySQL and MariaDB write the offending value into it (`Duplicate entry 'x' for key ...`, `Incorrect integer value: 'x' for column ...`, a syntax error's `near '...'`). `QueryExecutor->new(error_masker => ...)` masks every text before the exception is built (prepare/execute/query callbacks, a croaking execute, a dispatch EV::MariaDB refuses, the reset); `Storage::_executor` passes `Storage::_mysql_mask_error` (`DBIO::MySQL::Util::mask_error_details` then `DBIO::Util::mask_bound_values`, a function, so it never connects the owner's dbh). The listen connection's own statement runner masks with the notify statement's binds (the payload is a value). `sqlstate` stays. EV::MariaDB prepares on the server (binds never enter a syntax excerpt, only literals of the statement do); a refused prepare reaches the Future as plain text, the handle holds no SQLSTATE then. Pinned by `t/64-error-values-mock.t`, `t/64-error-values-live.t`
- NO pipeline mode (ADR 0009): EV::MariaDB has nothing to bracket. `pipeline()` returns a failed Future naming the transport -- use several `*_async` calls (each on its own pooled connection) or `txn_do_async`
- LISTEN/NOTIFY is EMULATED over a notify table (`DBIO::MySQL::NotifyTable`) polled on an EV timer, on a dedicated connection outside the pool (ADR 0010, karr k44)
- `transport_capabilities`: `on_connect_replay`, `listen`, `notify`, `broker_connect_options` -- no `copy`, no `pipeline`
- Concurrent over TLS through a work-around (karr k85): libmariadb 3.4.9 leaves a TLS socket blocking, so a bare EV::MariaDB handle holds the whole EV loop for every statement. `Pool::_mysql_new_handle` (the one place every handle is made) sets `O_NONBLOCK` on the socket in `on_connect` -- again after every reconnect -- on every handle, not only one whose connect info has `ssl_*` parameters (karr k95: the flag was measured to change nothing over plain TCP, and the connect info does not say whether TLS was negotiated; measured, libmariadb 3.4.9 negotiates TLS against MySQL 8.0 and MariaDB 11.8 only with a `ssl_*` parameter). Limits: the connect and the TLS handshake still block. Not measured: a Unix socket (`mysql_socket`). close/finish/TLS shutdown measured clean. Upstream draft `docs/upstream/ev-mariadb-tls-blocks-the-loop.md` (not sent); pinned by `t/60-tls-nonblocking-socket-mock.t` and `t/52-tls-concurrent-live.t`

## Dependencies

`cpanfile` is the source: DBIO, DBIO::MySQL, EV >= 4.15, EV::MariaDB >= 0.08,
Future >= 0.49. What DBIO core already ships transitively (DBI, namespace::clean,
...) is not re-declared here.

## Connecting

```perl
package MyApp::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL');

my $schema = MyApp::Schema->connect(
  'dbi:MariaDB:database=myapp;host=localhost', $user, $pass,
  { async => 'ev' },
);

# AccessBroker: the connect options go beside the broker. Static takes
# host / port / dbname / username / password -- nothing else.
my $broker = DBIO::AccessBroker::Static->new(
  host     => '127.0.0.1',
  dbname   => 'myapp',
  username => 'app',
  password => 'secret',
);
my $schema = MyApp::Schema->connect($broker, { async => 'ev', pool_size => 10 });
```

## Async Methods

```perl
# ResultSet / Row level
$schema->resultset('Artist')->all_async->then(sub { my @artists = @_; ... });
$schema->resultset('Artist')->create_async({ name => 'Tom' })->then(sub { my $row = shift; ... });

# Storage level, on the backend. Source/SQLMaker arguments, never raw SQL.
my $storage = $schema->storage->async;       # DBIO::MySQL::EV::Storage
my $source  = $schema->source('Artist');

$storage->select_async($source->name, '*', { active => 1 }, { order_by => 'name' })
  ->then(sub { my @rows = @_; ... });        # raw row arrayrefs

$storage->select_single_async($source->name, '*', { name => 'Tom' })
  ->then(sub { my $row = shift; ... });      # one row arrayref, or undef

$storage->insert_async($source, { name => 'Tom' })
  ->then(sub { my $returned = shift; ... }); # returned-columns hashref, auto-increment id included

$storage->update_async($source, { active => 0 }, { name => 'Tom' })
  ->then(sub { my $count = shift; ... });    # affected rows

$storage->delete_async($source, { name => 'Tom' })
  ->then(sub { my $count = shift; ... });    # affected rows

$storage->txn_do_async(sub {
  my $ctx = shift;                           # pinned connection
  $ctx->insert_async($source, { name => 'Tom' })
    ->then(sub { $ctx->select_async($source->name, '*', { name => 'Tom' }) });
});
```

Those shapes are binding (ADR 0031 §3). MySQL has no `RETURNING`: `insert_async`
reads `LAST_INSERT_ID()` on the same pinned connection, and puts it into the
hashref only when `$source` is a result source -- a bare table name gives back
the insert data alone. A value the caller supplied for the auto-increment column
is kept (karr k68); a 0 there is "generate" unless the session's `sql_mode` has
`NO_AUTO_VALUE_ON_ZERO` (read on the pinned connection, only for a 0). An upsert is planned by the owning sync storage's
`_mysql_upsert_plan` (told `returning => 0`, karr k47) and the whole plan counts:
where it cannot name the row the primary key is withheld and the reason reported
once, as in the sync insert.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/     # offline; the live files skip themselves
```

- Offline: every `*-mock.t` and the other files that need no server. No `prove -j`, one suite at a time.
- Live: every `*-live.t`, plus `t/10-integration.t` and `t/13-async-e2e.t`. They need `DBIO_TEST_MYSQL_DSN` (`_USER`, `_PASS`) and EV + EV::MariaDB, and skip otherwise.
- `t/51-async-parity-live.t` drives core's `DBIO::Test::AsyncParity` (the ResultSet cases, sync vs `*_async`) in a database of its own, `mysql_ev_parity`, dropped at the end. Its deviations (cases that fail on both ways) are declared in the file with the reason.
- A live test that needs a pooled backend goes through `DBIO::MySQL::EV::TestHarness` (`skip_all_unless_live`, `warm_pool`, ...): only that wires the backend to an owning sync storage.

### Live run

House rules for live testing apply (`.claude/rules/.local.dbio-rules.md`): one
run at a time, serial, one DB, every suite through `capped-test`.

The maintainer's databases stand in the cluster namespace `dev-dbio`, managed by
`dbio-db`; there is no port-forward. `<cihq-ocp>` is your checkout of the
cihq-ocp repo:

```bash
../dbio/maint/live-preflight && eval "$(<cihq-ocp>/umgebungen/dbio/dbio-db env mysql)" &&   ../dbio/maint/capped-test prove -l t/10-integration.t     # or: env mariadb
```

The standing databases stay up; `dbio-db up <db>` / `down <db>` start and remove one.

Without that infrastructure, `maint/k8s/mysql-pod.yaml` is a MySQL 8.0.30 pod
with cpu/memory caps; its header has the `kubectl apply`, `port-forward`,
`DBIO_TEST_MYSQL_*` and `kubectl delete` steps. Delete the pod afterwards.

## Pool and connect info

- `DBIO::MySQL::EV::Pool` supplies the EV::MariaDB connection seam and what only this transport knows about its connections (fork guard, gone-connection check, marked waiter); acquire / release / waiter queue / capacity / readiness gate are core's `DBIO::Storage::PoolBase` (ADR 0003).
- Static connect info is normalized once, in `connect_info` (`_normalize_async_connect_info`: `dbname` -> `database`, `pool_size` taken out), and stored; `_conninfo_hash` returns it as is, and the pool is built from it.
- With an AccessBroker nothing is stored and `_conninfo_hash` returns `undef`. The pool is built with the `_conninfo_provider` coderef instead, which calls `_async_broker_conninfo` for each new pooled connection -- rotated credentials reach the next connection without a pool teardown. `connect_info` reads the answer once, to refuse one it cannot connect from and for its `pool_size`.
