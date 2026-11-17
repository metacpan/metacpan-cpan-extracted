---
name: dbio-mysql-ev
description: Load when working on the DBIO::MySQL::EV driver — EV::MariaDB `ev` async transport, pool, transaction pinning, AccessBroker.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::MySQL::EV

The native `ev` async transport for MySQL/MariaDB (core ADR 0030 / 0031). It speaks
MariaDB's C client library through EV::MariaDB; the pooled connections carry no DBI
handle and no DBD. The dist requires `DBIO::MySQL`: the sync driver registers the
`ev` mode and owns the SQL (SQLMaker, DDL, `mask_error_details`).

Core knowledge (storage seams, async transport, live testing) is in
`dbio-driver-development`: `references/async-transport.md` for the transport and
AccessBroker seams, `references/live-testing.md` for live runs.

## Namespace

| Class | Purpose |
|---|---|
| `DBIO::MySQL::EV` | Marker component: no methods, no `connection()` hook |
| `DBIO::MySQL::EV::Storage` | The transport — a `DBIO::Storage::Async` subclass |
| `DBIO::MySQL::EV::Pool` | EV::MariaDB connection pool — a `DBIO::Storage::PoolBase` subclass supplying the connection seam (`_create_connection` / `_new_connection` / `_shutdown_connection`), the fork guard (`_verify_pid`), the gone-connection check (`_mysql_connection_gone`) and its borrow-time use (`_idle_connection_alive`), the marked waiter (`_new_waiter`) and the held-by-callbacks check (`_mysql_held_by_callbacks`) |
| `DBIO::MySQL::EV::QueryExecutor` | Wire seam: EV::MariaDB `query` vs prepare/execute; settles Futures from an idle watcher; knows per connection whether one of its settlings runs and whether a statement is in flight |
| `DBIO::MySQL::EV::Future` | The transport's `future_class` — a `Future` whose `await` runs the EV loop, and refuses a blocking wait that cannot end |
| `DBIO::MySQL::EV::TransactionContext` | Pinned connection for `txn_do_async` — thin subclass of core's `DBIO::Storage::Async::TransactionContext`, adds only the `txn_mdb` alias |
| `DBIO::MySQL::EV::ConnectInfo` | `dbi_to_conninfo` — DBI DSN → EV::MariaDB named params |
| `DBIO::MySQL::EV::TestHarness` | Installable live harness; ships under `lib/`, not `t/` — thin subclass of core's `DBIO::Test::AsyncHarness`; declares the four `harness_*` values, `_tick_loop` and the default schema, and offers `count_session_status` / `session_status` |

## Reaching the transport

Async is an explicit per-connection mode (ADR 0030). The `ev` mode is registered
by the **sync** driver — `DBIO::MySQL::Storage` calls
`register_async_mode( ev => 'DBIO::MySQL::EV::Storage' )` — and core resolves it
by walking the *storage* MRO. The schema's component list takes no part in it.

```perl
package MyApp::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL');   # the driver: picks the sync storage

my $schema = MyApp::Schema->connect(
    'dbi:MariaDB:database=myapp;host=localhost', $user, $pass,
    { async => 'ev' },
);
```

The only opt-in is `{ async => 'ev' }` at connect; readiness of the pool comes from
`DBIO::Storage::PoolBase`. `load_components('MySQL::EV')` is a **no-op marker**: the
component defines no methods, pins no `storage_type` and does not make the `ev` mode
resolvable. That inertness is the contract (ADR 0032 §7: an extension never decides
the driver), guarded mechanically by `t/00-load.t`.

The DBI DSN is translated to EV::MariaDB named parameters by
`ConnectInfo::dbi_to_conninfo` (`dbname` → `database`), which takes
`[$dsn, $user, $pass, \%attrs, \%extra_attributes]`. Of the two attribute
hashes only `pool_size` is read (default 5), the later one winning; DBI attributes
and the storage's own are dropped — EV::MariaDB croaks on an argument it does not
know. A `mysql_*`/`mariadb_*` attribute EV::MariaDB has a parameter for is read like
the same DSN key (`mysql_enable_utf8mb4` is `charset => 'utf8mb4'` + `utf8 => 1`;
DBD::mysql only), any other is refused, named. `mysql_auto_reconnect` /
`mariadb_auto_reconnect` with a false value asks for nothing and passes; a true one
is refused. An unknown DSN key or a lowercase non-DBI attribute is refused, never
dropped. Every handle is made with `found_rows => 1` (CLIENT_FOUND_ROWS, as the
DBDs; `mysql_client_found_rows=0` turns it off), `Pool::_mysql_new_handle`.

No message quotes a password: every text that names connect info or passes on the
client library's goes through core's `DBIO::Util::mask_connect_secrets` — the DSN
`dbi_to_conninfo` does not read, the croak of `EV::MariaDB->new` and every
`on_error` text (both in `Pool::_mysql_new_handle`, the one place every handle is
made — pooled and the listen connection, never `EV::MariaDB->new` directly), and
the pool's warning. A new message about a connection names shapes and keys, or is
masked the same way. Pinned by `t/40-no-password-in-messages-mock.t`.

An error text names keys, columns and options, never a value (core ADR 0075).
`QueryExecutor->new(error_masker => ...)` masks every text before the exception is
built; `Storage::_executor` passes `Storage::_mysql_mask_error`
(`DBIO::MySQL::Util::mask_error_details`, then `DBIO::Util::mask_bound_values`).
Pinned by `t/64-error-values-mock.t` and `t/64-error-values-live.t`.

A hash answer of a broker is this transport's shape, and a **schema's** sync
owner takes less of it (core's rules, held by
`t/41-access-broker-client-parameter-mock.t`): it needs a `dbname` (or `dsn`) —
without one `Schema->connect` throws — and it refuses a hash carrying a client
parameter (`charset`, …) when it opens its dbh, while the pool connects with it. A
test broker that answers a schema therefore answers `dbname`, and a client
parameter for a schema's pool comes from `connect_info_for_storage`.

## AccessBroker

The connect options go beside the broker, or the broker goes to the transport
directly:

```perl
my $schema  = MyApp::Schema->connect($broker, { async => 'ev', pool_size => 10 });

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([$broker]);                       # per-spawn credential provider gets wired
$storage->connect_info([$broker, { pool_size => 10 }]);  # with connect options beside it
```

The transport declares `broker_connect_options`, so core hands it the options
beside a broker as `[ $broker, \%options ]` whenever they hold something a backend
applies (`pool_size`, DBD attributes); the owner's own options alone leave it the
bare `[ $broker ]`. The `connect_info` override takes the two-element form only
through core's seams: `_strip_private_connect_attrs` + `_access_broker_call_options`
split the options, `_access_broker_pool_size($answer, $beside)` sizes the pool
(answer hash, DBI-form slots [3]/[4], beside the broker; answer and beside must
agree or it throws naming `pool_size`). DBD attributes beside the broker are
dropped like the same keys in DBI-form connect info. The declaration is a promise:
`t/30-access-broker-connect-options-mock.t` holds the behaviour behind it.

A connection parameter beside the broker (`charset`, `connect_timeout`, `host`, any
lowercase key that is no DBI attribute: uppercase first letter, `private_`, `dbi_`,
`dbd_`, and here both `mysql_` and `mariadb_`, since the transport is not told which
DBD the owner uses) is refused, never dropped:
`_mysql_refuse_parameters_beside_broker` croaks naming the keys, no value, from
`connect_info` and again from `_async_broker_conninfo` for every connection, so a
refused storage opens nothing. Through a schema that is the first `->async`, not
`connect`. Such a parameter belongs in the broker's answer. Pinned by
`t/39-access-broker-parameters-beside-mock.t` and its `-live.t`.

The broker is re-consulted per pooled connection through `_async_broker_conninfo`,
so rotating credentials reach new connections without a pool teardown. The listen
connection asks it the same way at every open.

`_async_broker_conninfo` reads every built-in broker's answer into EV::MariaDB
**named parameters** — EV::MariaDB parses no DSN and croaks on an argument it does
not know, so a string never reaches it:

| Answer | Broker | Read as |
|---|---|---|
| `[ 'dbi:mysql:…' \| 'dbi:MariaDB:…', $user, $pass, \%attrs ]` | Vault, HostBound over it | `dbi_to_conninfo`: DSN parts + user + password; of `\%attrs` (and a fifth-element hash) only `pool_size` |
| `{ host, port, dbname, user, password }` | Static, HostBound over it | as is, `dbname` → `database` |
| `[ \%conninfo, \%opts ]` | a custom broker | as is |

Anything else (a DSN for another driver, a plain string, a coderef) croaks via
`_mysql_broker_connect_info`, naming the **shape**, never a value — the answer
carries the password. So does an answer in one of these shapes that names
**neither `host` nor `user`**: `EV::MariaDB->new` starts a connect only when
given one of the two, and otherwise returns a handle that never connects and
never calls back, so the pool's `acquire` would never resolve. `connect_info`'s
broker branch reads the first answer through the same helper, so an unusable
broker is refused at attach. A Vault broker may pick this transport in its own
attributes: `dbi_attrs => { async => 'ev' }`.

**A whole DSN as the database name is refused.** `Static->new(dbname => 'dbi:mysql:…')`
is the form core's sync storage takes as the DSN, but the broker answers a hash; read
as a database name with no host, it would connect to the client library's default
(the local server) with the broker's credentials. The same helper refuses it (`dbi:`
at the start of `dbname`/`database`/`db`), at attach and for every connection, under
a HostBound view too, saying nothing of the DSN. The broker answers the DBI form, or
`dbname` with `host`/`port` beside it.

**A broker connection is opened from the broker's current answer or not at all.**
`connect_info([$broker])` — with or without options beside the broker — reads the
answer once, to refuse an unusable one and for its `pool_size`, and stores no
conninfo: `{_conninfo}` is `undef` with a broker attached, and `_conninfo_hash`
returns the *static* conninfo only.

- `clear_access_broker` (public, on `DBIO::Storage`) leaves the per-spawn
  provider in place — on the storage and in a pool already built with it.
  `_async_broker_conninfo` croaks `no AccessBroker attached` there instead of
  reading core's `_current_async_connect_info`, which answers the *stored*
  conninfo when no broker is attached.
- After `_clear_access_broker` (broker and provider gone) a storage has nothing
  to connect from until `connect_info` is called again: `pool` croaks
  `conninfo or conninfo_provider required`, `_listen_open` croaks
  `the listen connection has no connect info`.

A broker's answer is never stored, and no path a broker connection takes falls back
to stored conninfo. Pinned offline by `t/29-access-broker-conninfo-mock.t`.

## Async API — signatures and resolution shapes

The five `*_async` methods are **inherited** from `DBIO::Storage::Async` and take
source/SQLMaker arguments, never raw SQL strings:

```perl
$storage->select_async($source, $select, $where, $attrs);   # → raw row arrayrefs
$storage->select_single_async($source, $select, $where, $attrs); # → one row arrayref
$storage->insert_async($source, \%vals);                    # → returned-columns hashref
$storage->update_async($source, \%vals, \%where);           # → affected-row count
$storage->delete_async($source, \%where);                   # → affected-row count
```

Those shapes are binding (ADR 0031 §3) — the core `create_async` /
`Row::insert_async` helpers fold `insert_async`'s hashref back via
`_store_inserted_columns`. MySQL has no `RETURNING`, so `_post_insert_sql` is
empty and the transport reads `SELECT LAST_INSERT_ID()` on the **same pinned
connection** as the INSERT to build that hashref. A value the caller supplied for the
auto-increment column is kept; a 0 there means "generate" unless the session's
`sql_mode` has `NO_AUTO_VALUE_ON_ZERO` (read on the pinned connection, only for a 0).
An upsert is planned by the owning sync storage's `_mysql_upsert_plan` (told
`returning => 0`) and the whole plan counts: where it cannot name the row the primary
key is withheld and the reason reported once, as in the sync insert.

`then` callbacks may `return` a plain value; Future.pm wraps it (ADR 0031 §4).

EV::MariaDB drives the EV loop, so this works under EV directly, AnyEvent (with
the EV backend), `IO::Async::Loop::EV` and `Mojo::Reactor::EV` — and only there.

## Blocking methods — `->get` runs the EV loop, and refuses a wait that cannot end

The sync methods (`select`, `insert`, `txn_do`, `deploy`, …) are core's
`X_async(@_)->get`, inherited. They block because `future_class` is
`DBIO::MySQL::EV::Future`, whose `await` runs `EV::run(EV::RUN_ONCE)` until the
Future is ready (ADR 0001). That works at top level, in a plain EV callback, inside
a `then` on the transport's own Futures and in a `txn_do` / `txn_do_async` coderef,
`$ctx->select` without binds included.

Why it works there (ADR 0001 addendum): `QueryExecutor::_settle_cb` does not settle
a statement's Future inside the EV::MariaDB callback; it queues the settling
(`_defer`) and an `EV::idle` watcher (`_drain`) runs it, oldest first, one watcher
for all connections. What a `then` or the `txn_do` coderef runs is therefore outside
every callback of the handle (callback_depth 0), and EV::MariaDB sends a statement at
once instead of queueing it until the callback returns. The wire work stays in the
callbacks (prepare → execute → `close_stmt`); only the `IN_FLIGHT` down-count,
`done`/`fail` and `_start_next` run in the watcher, in that order. Consequence: plain
queries a coderef issues back to back go out one after the other — the first goes
out, the next ones wait for its answer (one more round trip each).

One wait cannot end, and `await` refuses it with `Blocking wait refused: …` instead
of hanging:

| The blocking call | Why it cannot end | What the refusal does |
|---|---|---|
| is **queued for a pooled connection** while the settlings it runs inside hold every connection (`$storage->select` in a `txn_do` coderef with a pool of one, or under N nested transactions with a pool of N) | a transaction gives its connection back only after `COMMIT`/`ROLLBACK`, which core sends only after the coderef returned | the queued caller is taken out of the pool's queue and failed; the call **never runs** (a refused insert writes nothing) |

A `txn_do` coderef then fails, the transaction is rolled back and its
connection goes back to the pool. The answer for callers: in a transaction
coderef use the context (`$ctx->X_async` chained with `then`, or the blocking
`$ctx->X`) for a statement of the transaction; for a statement outside it use
`$storage->X_async` chained with `then`; or raise `pool_size`.

The refusal is decided by three conditions together; each one alone refuses waits
that would have ended (`t/33-blocking-on-exhausted-pool-mock.t` has a case per
condition):

1. **The awaited Future is chained off a queued caller.** `Pool::_new_waiter`
   (core's waiter seam) marks the Future a queued caller waits on;
   `Future::new` called on an instance — how Future.pm makes the Future of every
   `then` — carries the mark along (as `udata`, never as a hash key of the
   instance). A queued call nobody blocks on is left alone and runs later.
2. **A settling of the connection is running** — the `%FRAME` `_drain` sets
   around every settling it runs (a `then` chain, a `txn_do` coderef).
3. **No statement is in flight on it** — the executor's per-connection count of
   dispatched statements whose Future has not settled. A statement in flight
   may be what gives the connection back, so the wait goes on, and is asked
   about again after every loop iteration and when the loop runs dry.

`Pool::_mysql_held_by_callbacks` is 2 and 3 for every connection the pool holds,
with none idle. Not covered: a blocking wait on a Future that reaches a queued
caller without being chained off it (a `then` callback that *returned* a storage
call's Future), and a transaction whose coderef returns a Future that depends on
a call queued for the transaction's own connection — no blocking wait inside a
callback, so nothing refuses it.

Condition 3 is the executor's count, not EV::MariaDB's `pending_count`: what
gives a connection back is the chain that runs when a statement's *Future*
settles, so that is what is counted. The refusal settles the queued caller only
after `PoolBase::_withdraw_waiter` took it out of the queue.

## No pipeline mode (ADR 0009)

`$storage->pipeline(\&batch)` is **not usable here**. EV::MariaDB exposes no
bracketing primitive, so this transport overrides none of core's
`_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit` seams and does not
declare the `pipeline` capability. The call is refused by core's
`_pipeline_refusal`: it returns a **failed Future** saying that
`DBIO::MySQL::EV::Storage` does not support `pipeline()` — no throw, no
connection taken from the pool, the batch never runs. `$ctx->pipeline` on a
transaction context gets the same answer and leaves the transaction's
connection alone. Pinned by `t/35-pipeline-refusal-mock.t` and
`t/txn-context-pipeline-mock.t`. An async layer that requires `pipeline` is
refused at compose time, naming the gap.

What the driver offers instead is **concurrency, not batching**: issue several
`*_async` calls without awaiting and gather them.

```perl
Future->needs_all(
    map { $storage->insert_async($source, { name => $_ }) } @names
)->then(sub { ... });
```

Each of those runs on **its own pooled connection**, so the statements overlap on
the wire. EV::MariaDB does batch consecutive queries on *one* connection (up to
64 in flight), but the pooled CRUD path takes a connection per call, so that is
not something this driver can promise. Want atomicity? Ask for it: `txn_do_async`.

## Thin transport — what lives here and what does not

`t/06-thin-transport-structure.t` freezes this. The Model-B orchestration (CRUD
runner, `txn_do_async`, `sql_maker`, sync `->get` fallbacks) is inherited
unchanged; a parallel reimplementation fails that test. Defined here:

- `sql_maker_class` / `_sql_maker_args` — the shared `DBIO::MySQL::SQLMaker`
- `_transform_sql` — **identity**. `?` is MySQL's native placeholder, so the seam
  exists only to honour the uniform `?`-in contract. SQL is shaped once, inside the
  transport, never in a caller or a layer.
- `_query_async` / `_query_async_pinned` — dispatch via `QueryExecutor`, both
  through `_mysql_execute`, which reports a failed statement's connection to
  the pool when it is gone (see *Dead connections* below); a pinned `ROLLBACK`
  goes through `_mysql_rollback` and a pinned `COMMIT` through `_mysql_commit`
  instead (*The end of a transaction* below). Both take the optional `$bind_attrs`;
  wire binds stay bare values
- `_await_query_result` — the pooled dispatch `_query_async` hands to core's
  `_seam_future` by name; `insert_async` hands it `_run_crud_pinned` the same
  way. A dispatch that dies or returns no Future fails the call and still
  releases the pooled connection (`t/31-seam-returns-no-future-mock.t`)
- `insert_async` / `_run_crud_pinned` / `_insert_returned_columns` — the
  INSERT + `LAST_INSERT_ID()` path core's RETURNING-shaped runner cannot serve
- `_run_pool_connect_statement` — connect-action replay on a fresh pool connection
- `connect_info` / `_normalize_async_connect_info` / `_conninfo_hash` — conninfo shape
- `_txn_context_class` / `_txn_conn_accessor` (`'txn_conn'`, core's key) —
  transaction pinning. The context class is a **thin subclass** of core's
  `DBIO::Storage::Async::TransactionContext`: the whole context surface,
  `_context_active`/`_invalidate` (ADR 0045) included, is inherited; only `txn_mdb`
  (an alias for the inherited `txn_conn`) is added here
- `_ddl_class` — `DBIO::MySQL::DDL`, so `deploy_async` emits the sync deploy's DDL

The statement trace is core's (`DBIO::Storage::Async::_debug_query`, core ADR 0025):
`Storage::_mysql_execute` and the pinned ROLLBACK/COMMIT/reset call it once per
statement and hand `query_end` to the Future's `on_ready`; the QueryExecutor traces
nothing. Pinned by `t/61-trace-core-mock.t`, `t/62-trace-core-live.t`.

`transport_capabilities` is exactly `on_connect_replay listen notify
broker_connect_options`: `listen`/`notify` for the notify-table emulation (ADR
0010), `broker_connect_options` for the connect options beside an AccessBroker
(above; read by core, not by layers). MySQL has no COPY, and pipeline is
declined — so nothing else is advertised, and an async layer requiring more is
refused at compose time.

`deploy_async` runs statement-at-a-time and is **not** wrapped in a transaction:
MySQL implicitly commits each DDL statement (ADR 0026), so a half-way failure
leaves what already ran — re-run with `add_drop_table => 1`.

## Pool — opts into core's readiness gate, does not implement it

`DBIO::MySQL::EV::Pool` overrides six `PoolBase` methods (ADR 0003; ADR 0010 for the
gone-check seam; ADR 0001 addendum for the marked waiter):

- `_create_connection($conninfo)` — shapes the already-normalized conninfo into
  named args and hands them to core's `_create_ready_connection`; arms the
  pool's fork watcher with the first connection
- `_new_connection(%args)` — the raw handle seam, made through
  `_mysql_new_handle` (`EV::MariaDB->new` with its croak and every `on_error`
  text masked — the listen connection's handle is made there too); the
  handle's `on_error` reports the connection when it is gone, then runs core's
- `_shutdown_connection($mdb)` — `close_async`, guarded against an undef slot
- `_verify_pid` — keeps a weak reference to the parent's connections before
  core drops them in a forked child, for the fork watcher to finish
- `_new_waiter` — core's waiter, marked with the pool that queued it
  (`Future::_queued_in`), so a blocking wait can tell it waits for a queued
  caller (*Blocking methods* above)
- `_idle_connection_alive($mdb)` — core's borrow-time seam: an idle
  connection is vouched for unless `_mysql_connection_gone` (*Dead connections*
  below)

and adds `_mysql_connection_gone` / `_mysql_report_if_gone` (*Dead connections*
below) and `_mysql_held_by_callbacks` (*Blocking methods* above). Everything else,
**including the connection-readiness gate**, comes from `DBIO::Storage::PoolBase`:
`_create_ready_connection` wires `on_connect`/`on_error` to a per-connection
readiness Future and registers it, and the base's default
`_connection_ready_future` looks it back up, so `acquire` resolves only on a
connected handle and *fails* (never hangs) on a refused connect.

Opting in is explicit: `_create_connection` is a required core hook because only a
**callback-shaped** transport can use the default. `EV::MariaDB->new` takes
`on_connect`/`on_error` as constructor args and installs them before it starts
connecting — that is what qualifies this driver. A **poll-shaped** transport (no
connect callbacks; readiness established by probing, as in `dbio-async`'s
`future_io` adapter with `_conn_ready` + `Future::IO->poll`) overrides the seam
itself. `t/08-pool-readiness.t` pins the opt-in offline by subclassing the pool at
`_new_connection` and firing the fake callbacks by hand.

**The session is reset when a borrow ends** (core ADR 0079, ADR 0011).
`Storage::_reset_pool_connection` sends `COM_RESET_CONNECTION`
(`QueryExecutor::reset_connection`), then sets the connection's character set and
collation again (`SET NAMES <charset> COLLATE <collation>`, the two names read once
per connection after the connect actions of its spawn, checked for `[A-Za-z0-9_]`),
then replays the connect actions (`_setup_pool_connection`). The pool hands the
connection on only after all three answered; a failure or a missed `reset_timeout`
retires it. There is no opt-out: every borrow has the session of a new connection,
character set and collation included. Pinned by `t/59-session-reset-mock.t` and
`t/58-session-reset-live.t`.

**TLS runs concurrently through a socket flag.** libmariadb leaves a TLS socket
blocking, so a bare EV::MariaDB handle holds the whole EV loop for every statement.
`Pool::_mysql_new_handle` (the one place every handle is made) sets `O_NONBLOCK` on
the socket in `on_connect` — again after every reconnect — on every handle, since the
connect info does not say whether TLS was negotiated. Limits: the connect and the TLS
handshake block; a Unix socket (`mysql_socket`) has no TLS test. Upstream draft:
`docs/upstream/ev-mariadb-tls-blocks-the-loop.md`. Pinned by
`t/60-tls-nonblocking-socket-mock.t` and `t/52-tls-concurrent-live.t`.

## The end of a transaction — ROLLBACK waits, a failed ROLLBACK or COMMIT retires

EV::MariaDB takes no `query` while a `prepare` or an `execute` is in flight
(`cannot queue query: exclusive operation in progress`; `close_stmt` is never in
flight, its callback has run when it returns, and a query behind it is taken —
`t/37-txn-rollback-refused-live.t` part R). A statement with bind values is all
three. A `ROLLBACK` therefore waits behind the statements in flight on its
connection; one handed over at once would be refused, never reach the server, and
leave the transaction open on a connection the pool hands on. This happens when a
statement of the transaction is cancelled, when the coderef dies and when the
coderef's Future fails, with a bound statement still on the wire.

- **Order per pinned connection.** `Storage::_query_async_pinned` sends a
  `ROLLBACK` through `_mysql_rollback` -> `QueryExecutor::execute_when_idle`:
  with nothing in flight it goes out at once; otherwise it is queued and handed
  to EV::MariaDB when the last statement in flight is settled by the idle
  watcher. Every statement on a pinned connection queues behind a prepare/execute in
  flight. Several waiting statements start one after the other, and one that sends
  nothing when its turn comes (its Future was cancelled while it waited, its handle
  is gone, EV::MariaDB refused it) does not strand the ones behind it:
  `_start_next` goes on until one is in flight or none is left. `COMMIT` goes
  through `_mysql_commit` and is **not** queued: core sends it only after every
  statement of the context has settled.
- **Bounded wait.** The storage attribute `rollback_wait_timeout` (seconds, default
  30, 0 = unlimited) bounds the wait: then the ROLLBACK is not sent, the connection
  is retired, and the transaction fails with a reason. Pinned by
  `t/57-rollback-wait-timeout-live.t`.
- **Retire.** A `ROLLBACK` or a `COMMIT` that fails — refused at dispatch,
  failed by the server or the client library — reports its connection to the
  pool with `_mark_connection_dead` (`_mysql_end_transaction`): it is retired
  when core hands it back, never idle with a transaction possibly open. This is
  on top of the gone-check, and applies whether or not the session is "gone". The
  caller still gets core's `COMMIT failed: ...`, and the next call runs on a newly
  opened connection.
- **Consequences for callers.** The transaction future settles when the statement in
  flight does (a `SLEEP(1.5)` cancelled in a transaction ends the transaction after
  those 1.5 s, not at the cancel). A dying coderef's `insert_async` still reads its
  `LAST_INSERT_ID()` inside the transaction before the `ROLLBACK`. The failed
  transaction's error is the cause of the failure.
- **Not covered.** A statement in flight whose callback never comes (handle
  dropped without a callback) keeps the `ROLLBACK` queued and the transaction
  open; EV::MariaDB calls pending callbacks with an error on error/finish, so the
  live paths end. A statement queued *behind* the transaction's end on the same
  connection still hits the refusal itself.

Pinned offline by `t/36-cancel-in-flight-mock.t` (9, 11, 12, 13), live by
`t/37-txn-rollback-refused-live.t`.

## Dead connections — the handle decides, the pool retires

The pool cannot see a connection die. Two things tell it, both by the same
check:

- **Before a borrow** (ADR 0010): core asks `_idle_connection_alive` about every
  idle connection `acquire` is about to hand out. One that is gone is retired by
  core, and the caller gets the next idle connection that is still there, or a newly
  opened one. A session the server ended while its connection sat idle (`KILL`, a
  restart, `wait_timeout`) costs no caller a failed call.
- **After a failed statement** (ADR 0010): a connection that is gone is reported to
  core's `PoolBase::_mark_connection_dead`, and the pool retires it instead of
  handing it out again: at once when it is idle, at the release when it is checked
  out or pinned; a caller queued for the slot gets a newly opened connection. This
  catches a session that ended after the pool looked, or without the server saying
  so.

**What "gone" means** is one method, `DBIO::MySQL::EV::Pool::_mysql_connection_gone($mdb)`
— local, no round trip, never blocks:

| Handle | Answer |
|---|---|
| `socket` is -1 (never connected, closed, or the client library gave it up when an operation found the server gone) | gone |
| `pending_count` > 0 (a reply is due on the socket) | not gone |
| idle, socket readable (a MySQL server never speaks unasked: it hung up) | gone |
| idle, nothing to read | not gone |

`is_connected` is no signal: it stays true after the server ended the session and
after an operation failed on it (ADR 0010, fact 3). Neither the error text nor a list
of error numbers decides: once EV::MariaDB has dropped its client state (`not
connected`), `error_number` is 0.

**Who reports**, always before the release:

- `Storage::_mysql_execute` — every statement, pooled and pinned, goes through
  it. A statement that fails through its callback, or that EV::MariaDB refuses
  to dispatch, has its connection asked about. This is also what covers a
  transaction and `deploy_async`: core releases their connection, and core
  cannot be hooked there.
- the handle's `on_error` (`Pool::_new_connection`) — it **asks**, it does not
  assume: EV::MariaDB also sends the error of a secondary result set this way,
  on a session that is still there.

A statement that succeeds is never asked about, and a statement error the
session survives (syntax, duplicate key, a busy handle's refusal) leaves the
connection in the pool. Pinned offline by `t/32-pool-dead-connection-mock.t`.

**The borrow-time seam only answers.** `_idle_connection_alive` is
`!_mysql_connection_gone`: no report of its own (core retires what it asked
about), no operation on the handle, nothing sent, nothing read. It runs on
every borrow of an idle connection, so it stays that cheap: no `ping`, no statement.
An idle connection with an operation in flight (a caller that kept the handle;
nothing of the transport leaves one) is vouched for. Core asks only about
connections of the process that owns the pool: a forked child's first `acquire`
drops the inherited ones first.

EV::MariaDB calls back with the first result of a `CALL` sent without bind values
and reads the rest of the answer only after that callback returned. The executor
therefore sends a `CALL` without bind values through prepare/execute, where the whole
answer is read before the Future settles (`t/42-call-prepare-path-mock.t`); with that
path the gone-check calls no healthy connection gone, over plain TCP and TLS, on
MySQL and MariaDB (`t/32-pool-dead-connection-live.t`). One boundary is known: a
statement a session prepared itself, `PREPARE h FROM 'CALL p()'` then `EXECUTE h`
sent through `query`, can over plain TCP make the check retire the healthy idle
connection once (one reconnect, no error). A `CALL` or any statement the transport
builds, a `CALL` with bind values, and anything over TLS are not affected.

A test double that answers inside the dispatch call, or by hand, leaves the
Future pending until the loop's idle watcher runs: the test calls
`EV::run(EV::RUN_NOWAIT())` after the answer before it looks at the Future.

A test double speaks this surface: a fake handle under the real pool
answers `socket` and `pending_count` (a live session is a real socket with
nothing to read — `socketpair`) — without them every borrow of an idle
connection throws in the seam, and core retires the connection and reports
`Idle connection liveness check failed` — and a pool double that is not a
`DBIO::MySQL::EV::Pool` takes `_mysql_report_if_gone`.

## LISTEN / NOTIFY

LISTEN/NOTIFY is emulated over a notify table (`DBIO::MySQL::NotifyTable`) polled on
an EV timer, on a dedicated connection outside the pool (ADR 0010). The listen
connection takes the broker's current answer at every open. Pinned by
`t/22-listen-notify-mock.t` and `t/48-listen-probe-mock.t`.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/          # offline; live files skip themselves
```

Offline files need no server; one suite at a time, never `prove -j`. The live files
(`*-live.t`, `t/10-integration.t`, `t/13-async-e2e.t`) skip themselves without
`DBIO_TEST_MYSQL_DSN` (`_USER`, `_PASS`) and EV + EV::MariaDB.

For a live run, the maintainer's databases are reached with `dbio-db env mysql`
(or `mariadb`); `maint/live-preflight` in the core checkout looks at the namespace
first, and every suite goes through `capped-test`. Details:
`dbio-driver-development` `references/live-testing.md`.

```bash
../dbio/maint/live-preflight && eval "$(dbio-db env mysql)" && \
  ../dbio/maint/capped-test prove -l t/10-integration.t
```

Without those databases, `maint/k8s/mysql-pod.yaml` is a capped MySQL pod; its header
has the `kubectl` steps.

A live test that needs a real pooled backend goes through
`DBIO::MySQL::EV::TestHarness` (`skip_all_unless_live`, `warm_pool`,
`run_on_each_pooled_connection`, `query_on`): only that gives it a backend wired to
an *owning sync storage*, so `on_connect_do` / `on_connect_call` replay on each
freshly spawned connection. A directly-constructed storage has no owner and replays
nothing.

That whole surface is **inherited from core's `DBIO::Test::AsyncHarness`**. This
dist declares only `harness_env_prefix('DBIO_TEST_MYSQL')`,
`harness_async_mode('ev')`, `harness_required_modules([qw( EV EV::MariaDB )])`,
`harness_schema_class(...)`, plus `_tick_loop` (`EV::run(EV::RUN_ONCE())`) and the
default `_Schema`. `await`, `warm_pool` and the connected check are core's:
`PoolBase::acquire` gates on readiness on all three of its paths, so an acquired
handle is connected. The default `_Schema` loads `('MySQL', 'MySQL::EV')` on purpose
— the EV component is an inert marker and is *not* what makes the connection async,
but loading it here exercises that inertness against a real server.

The harness adds what only this transport can read:

- `DBIO::MySQL::EV::TestHarness->count_session_status` (call once, before the first
  borrow; idempotent, process wide) wraps `_reset_pool_connection` so the session's
  status counters are read right ahead of each `COM_RESET_CONNECTION`.
- `$h->session_status($conn)` answers `Com_begin`, `Com_commit`, `Com_rollback`,
  `Com_stmt_prepare` and `Com_stmt_close` summed per `thread_id` over all borrows of
  that session (a plain `SHOW SESSION STATUS` sees the current borrow only). It waits
  at most 10 seconds for the connection to leave its reset and returns undef when the
  session cannot be asked.

## Related

`dbio-mysql` (the sync driver and the `ev` registration), `dbio-driver-development`
(async transport seams), `docs/adr/` in this repo — 0009 for pipeline, 0002 for
transaction pinning, 0010 for the pool's dead-connection and notify seams, 0011 for
the session reset.
