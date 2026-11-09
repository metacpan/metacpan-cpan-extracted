---
name: dbio-async
description: Load when working on DBIO::Async or wiring a driver to the future_io async mode — storage skeleton, pool, TransactionContext, the driver seam contract.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Async

Shared, loop-agnostic async layer for DBIO drivers. `DBIO::Async::Storage` is a
concrete, DB-agnostic skeleton subclassing core `DBIO::Storage::Async`; a
DB-specific driver subclasses it and supplies only the DB-specific seam hooks.
The Future / Future::IO requirements live here, not in each driver — a sync-only
driver pulls no async deps.

## Activation — the `future_io` async mode (ADR 0030/0031)

Loading `DBIO::Async` provides the shared abstract Future::IO transport base
`DBIO::Async::Storage`; it registers **no** generic `future_io` mode. The mode is
selected per connection via `connect(..., { async => 'future_io' })` (ADR 0030 —
explicit, no auto-fallback) and its transport class is **resolved by convention**:
the core resolver derives `ref($storage) . '::Async'` off the concrete driver
storage — `DBIO::PostgreSQL::Storage` → `DBIO::PostgreSQL::Storage::Async` — and
croaks early if a driver ships no such adapter (ADR 0030 refinement / karr k65).
The adapter is a concrete subclass of `DBIO::Async::Storage` that supplies the
seam hooks below; the Model-B orchestration (CRUD runner, txn pinning, pipeline)
is inherited from core (ADR 0030 §4). Its `insert_async` resolves the
returned-columns hashref that sync `insert` returns (ADR 0031 §3), not raw
RETURNING rows.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::Async` | Dist entry point (loadable, no behaviour) |
| `DBIO::Async::Storage` | Abstract Future::IO transport base (extends core `DBIO::Storage::Async`; orchestration inherited) |
| `DBIO::Async::Pool` | Generic pool (extends core `DBIO::Storage::PoolBase`) |
| `DBIO::Async::Future` | The pool's waiter: a `Future` whose `await` drives `Future::IO` (ADR 0008) |
| `DBIO::Async::TransactionContext` | Thin subclass of core's generic `DBIO::Storage::Async::TransactionContext` |

## Subclass contract — seam hooks a driver supplies

A driver's adapter (convention name `DBIO::PostgreSQL::Storage::Async`) does
`use base 'DBIO::Async::Storage'` and overrides the DB-specific hooks. The
unimplemented ones croak `"Subclass must override …"`.

| Hook | Driver supplies |
|------|-----------------|
| `_submit_query($conn, $sql, $bind)` | dispatch the query on the wire, non-blocking. The **return value is ignored** — `_await_query_result` calls it in void context and then chains on `_await_readable` |
| `_collect_result($conn)` | read the ready result off the connection, as a Future. Takes the connection and **nothing else** (ADR 0044 / karr k11): a driver needing more of the result re-polls with `_await_readable($conn)`, carrying no SQL and no binds. A query cancelled in flight, or whose connection is closed under it (karr k39), may never reach it, or be cut off between re-polls: the connection is then retired or closed, not drained (karr k29) — never count on a later call to finish the read |
| `_conn_fileno($conn)` | the **raw** socket fd. The base dups it once per connection (`_conn_poll_fh`) and polls that handle — `Future::IO` needs a real filehandle, and a per-poll one is closed before the loop unwatches it |
| `_conn_ready($conn)` | **boolean**: is the connection ready for queries? `_await_conn_ready` returns a done Future when true, and polls until it is when not |
| `_normalize_conninfo($ci)` | driver's connect-info shape |
| `_create_pool_connection($ci)` | build a pooled connection |
| `_shutdown_pool_connection($conn)` | tear one down. A statement may still be on its wire (disconnect with a query in flight): the base has failed its caller and let go of the poll by then (`_abandon_flights_on`, ADR 0007) — close the handle as an idle one, do not cancel on the server. Nothing is handed to `_submit_query` for a hashref connection after it was closed |
| `_conn_error_is_fatal($conn, $error, ...)` | optional, default false (ADR 0006): **boolean** — did the query that just failed on `$conn` leave the connection dead? Asked for every failed query Future, pooled and pinned, with the Future's failure (message, then category and details); never for a query that succeeded or was cancelled. True ⇒ the base reports `$conn` to the pool (`_mark_connection_dead`) before the hand-back, which then retires it. Answered from the handle's local state or the error itself — never blocks, no round trip. A throw counts as dead and goes to the pool's `on_error` |
| `_idle_connection_alive($conn)` | optional, default true (ADR 0006, core ADR 0047 addendum): **boolean** — is the session behind the *idle* pool connection still there? Core's pool seam of the same name, which `DBIO::Async::Pool` delegates to the storage; asked on every borrow of an idle connection, not about a fresh spawn or one released straight to a queued caller. False or a throw ⇒ the pool retires it and takes the next idle connection or a fresh one; a throw also goes to `on_error`. Never blocks, no round trip |
| `_transform_sql($sql)` | SQL rewrite the driver needs (e.g. `?`→`$N`, or identity). Inherited as a croaking seam from core, called by the transport internally — callers never pre-shape |
| `_post_insert_sql` | **takes no arguments**: the suffix core's insert runner appends to the INSERT (e.g. `' RETURNING *'`). Inherited as a croaking seam from core |
| `_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit` | optional pipeline primitives, inherited as croaking seams from core. Not supplied ⇒ `pipeline()` **fails the returned Future**; there is no sequential degrade (core ADR 0030 §3). `_pipeline_sync` must not resolve before the batched result Futures are read off the connection — the scaffold exits and releases in its completion |
| `_listen_drain($conn)` | optional, for LISTEN/NOTIFY (ADR 0005, core ADR 0056): the notifications pending on the listen connection as an arrayref of `[$channel, $payload, $sender_pid]` in arrival order (`[]` when none), **or a Future of one** (an emulation's drain query, `_query_async_pinned`). Dies / fails on a dead connection — in socket mode also on EOF, or the loop spins on a closed socket. Never blocks |
| `_notify_sql($channel, $payload)` | optional: `($sql, \@bind)` in the `?` dialect for one notification; the payload **only** in the binds (ADR 0017 §3) |
| `_listen_poll_interval` | optional mode switch: `undef` (default) = socket-driven watch, positive seconds = timer-driven (emulation; the driver's POD must state latency = interval and on-commit delivery, core ADR 0056 §6) |
| `_listen_open` / `_listen_close` / `_listen_subscribe` / `_listen_unsubscribe` / `_listen_probe` | the listen connection's DB-specific seams, inherited as croaking seams from core — plus the driver's own `transport_capabilities` declaring `listen` / `notify` (the base declares neither) |

`_txn_context_class` and `_txn_conn_accessor` are **not** on that list: since
karr k13 `DBIO::Async::Storage` answers both itself, with
`'DBIO::Async::TransactionContext'` and `'txn_conn'`. An adapter names them only
when it wants a different context class or constructor key.

Everything else — `_run_crud`, `txn_do_async`, the `pipeline` bracketing, the
sync `->get` fallbacks, the generic Transaction/Pipeline contexts — is
**core's**, concrete in `DBIO::Storage::Async` since ADR 0030 §4, not this
dist's. What lives here is the transport: `future_class`, the pool
(`DBIO::Async::Pool`, its idle list / waiter queue inherited from core
`PoolBase`), `_query_async` / `_query_async_pinned`, the `_await_*` watcher
seam, `transport_capabilities`, and the one AccessBroker hook the transport
fills for core's per-spawn conninfo provider, `_async_broker_conninfo`.
Since karr k22 (ADR 0005) it also owns the Future::IO-generic half of core's
LISTEN/NOTIFY seams, once for every driver: `_listen_delay` (`Future::IO->sleep`),
the watch loop behind `_listen_watch` / `_listen_unwatch` (state on
`$conn->{_dbio_async_listen_watch}`, private steps `_watch_*`) and the pooled
`_notify_send` over `_query_async` + `_notify_sql`.
Since karr k26 / k28 (ADR 0006) it also tells the pool about dead connections on
the driver's word: `_query_async` and `_query_async_pinned` register
`_mark_dead_on_fail` on every query Future (ahead of `_release_on_ready` on the
pooled path), and `DBIO::Async::Pool` passes core's borrow-time
`_idle_connection_alive` on to the storage.

Both dispatch sites — `_query_async` (pooled) and `_dispatch_pinned` (pinned) —
call `_await_query_result` through core's `_seam_future` (karr k25 / k35, core
k229 / k252). A seam that dies fails the query with its error; one that returns
**no Future** (`undef`, a plain value) fails it with an error naming the backend
class and the seam. Either way `_conn_error_is_fatal` is still asked, and a
pooled connection still released.
A driver overriding `_await_query_result` returns a Future — unlike
`_submit_query`, whose return value is ignored.

**Statements in flight are held by the storage** (ADR 0007, karr k46 / k39; POD
`STATEMENTS IN FLIGHT` in `DBIO::Async::Storage`). Every statement
`_query_async` / `_query_async_pinned` put on the wire sits in a register on
the storage (`_flight_register`) with its connection and the pool it was
dispatched with, until its Future settles; the caller gets a Future **of its
own**, of the flight's class.

- A Future the caller **drops** (fire-and-forget, not a cancel) is carried
  through: the answer collected, `_conn_error_is_fatal` asked on a failure,
  the pooled connection handed back once or retired; also when it was dropped
  while still queued for the pool. No message is invented for its failure.
- A pooled connection is back in the pool **before** the caller's callbacks
  run.
- A connection the **pool closes** ends the flight on it —
  `DBIO::Async::Pool::_shutdown_connection` calls
  `$storage->_abandon_flights_on($conn)` before `_shutdown_pool_connection`.
  That is every close: each connection at `shutdown` (what `disconnect` and
  `DESTROY` run) and each retirement. The caller's Future **fails there**
  (`Statement abandoned in flight: … whether it took effect is unknown`), the
  poll is let go of, nothing is read off the closed connection, a late answer
  changes nothing. A callback dying there goes to the pool's `on_error`.
- A **hashref connection the pool closed gets nothing more sent**, with or
  without a statement in flight: it carries a pinned queue that only refuses
  (`not sent: this connection was closed …`), so a later statement — a
  transaction's next one, core's `ROLLBACK` — fails without reaching
  `_submit_query`. A connection handed back open never carries the mark. A
  connection that is no hashref has no place for it: the driver's handle
  refuses.
- `shutdown`, `release`, `disconnect` stay **core's**, not overridden. Where
  core closes nothing, nothing is ended: a forked child settles nothing of
  the parent's; nothing is settled in global destruction; a storage merely
  dropped with a statement in flight lets it complete and is freed after.
- A **flight inherited across a fork does nothing in the child**, even when
  the child's own loop resolves the parent's poll: `_await_readable` continues
  a poll only in the process that made it (`_in_this_process_cb`), elsewhere
  into a Future that never settles. No `_collect_result` in the child — also
  not through a driver's re-poll — so the parent's answer stays on the socket.
  (`dbio-async-core` § Invariants.)
- A driver with **its own pool class** calls `_abandon_flights_on` from its
  `_shutdown_connection`.

A query **cancelled in flight retires its connection** (karr k29 pooled, k33
pinned): the poll is dropped, but the statement is on the server and its result
unread, and the base neither drains it nor cancels it on the server. Pooled,
`_query_async` registers `_abandon_on_cancel`, which reports the connection to
the pool (`_mark_connection_dead`) before the release runs; pinned, the
statement queue reports it the same way and refuses everything later on that
connection. `_conn_error_is_fatal` is not asked — a cancel is no failure. A
cancel that comes while the caller still waits for the pool dispatched nothing
and retires nothing.

`_query_async_pinned` **serialises** the statements on one pinned connection
(karr k33; POD `THE PINNED STATEMENT QUEUE` in `DBIO::Async::Storage`): a
statement is dispatched only once the one before it on that connection has
settled, in the order issued, and the caller gets its Future at once. That
covers everything pinned — a transaction context, a pipeline context, core's
`BEGIN` / `COMMIT` / `ROLLBACK`, an emulated `_listen_drain`.

- The queue lives on the connection hashref under the reserved key
  `_dbio_async_queue` (next to `_dbio_async_poll_fh`) and is removed as soon as
  the connection falls idle. A connection that is **not a hashref gets no
  queue**: its statements are dispatched at once and the driver serialises them
  itself, cancel handling included.
- The connection counts as idle as soon as its statement has settled with
  nothing waiting behind it — **before** that statement's callbacks run (karr
  k34). So a synchronous statement issued from such a callback goes out at
  once; every statement of a `txn_do` block is one, since core runs the block
  from the callback of `BEGIN`'s Future. On `Future::IO::Impl::IOAsync` it
  goes out and then dies in its `->get` — the implementation's limit, not the
  queue's (*Future::IO implementation limits* below).
- One case cannot complete: a synchronous statement issued from a callback
  while statements issued before it still wait. Chain it (`->then`) or await
  the waiting ones first.
- When a statement fails and the driver calls its connection dead
  (`_conn_error_is_fatal`), the statements already waiting behind it are failed
  without being sent.

## Pipeline and transactions

- Sync methods are `->get` wrappers (ADR 0001); transactions pin one connection via `TransactionContext` (ADR 0002).
- Pipeline is a generic `pipeline(\&coderef)` bracketing over driver seam hooks, in **core** since ADR 0030 §4; a transport supplying no pipeline seams fails the returned Future rather than degrading to sequential (ADR 0003 amendment k14, core ADR 0030 §3) — `future_io` supplies none, batching is the `ev` transports' capability. The block is handed a **`DBIO::Storage::Async::PipelineContext`** pinned to the bracketed connection (core), not the storage — its CRUD routes through `_query_async_pinned`, so batching needs no driver cooperation. A call on the *storage* inside the block takes a pooled connection and is NOT batched; `_query_async` must not consult pipeline state (ADR 0003 amendment, karr k7).

## Future::IO implementation limits

What a `Future::IO` implementation does with this transport's polls is its
own, and some of it reaches a caller (POD `FUTURE::IO IMPLEMENTATIONS` in
`DBIO::Async::Storage`). As of Future::IO 0.23 and Future::IO::Impl::IOAsync
0.805, the newest releases; **nothing in `lib/` works around any of it**, and
whether something should is undecided (karr k37). `t/33` (built-in) and `t/34`
(IO::Async) hold the first, third and fourth as `TODO` on what the caller is
owed, with the transport's own part asserted hard beside it — so an upstream
fix shows as `TODO passed`, and an install never fails over it.

- **Built-in: a poll cancelled from inside another poll's callback kills the
  round** when it stood behind the resolving one (`Can't call method "fh" on an
  undefined value at Future/IO.pm line 890`), out of whatever `->get` drove the
  loop, on a Future that is already done (karr k37). Met by `Future->wait_any`
  over two pooled queries when the first issued wins, and by a `disconnect`,
  pool shutdown or `cancel` in a query's callback while a later statement is in
  flight. The transport's part is done by then (winner collected and released,
  loser retired, nothing stale on the loop's list).
- **Built-in: with read polls only and no timer it does not `select`** — it
  presumes every poll ready, in the order made, and sets the handle blocking
  for the callback. Statements in flight on several pooled connections are
  answered in the order issued, each waited for in turn. By design upstream;
  the reason the listen watch loop confirms readability itself. Not asserted
  in the suite.
- **IOAsync: a cancelled poll keeps its watch and the dup** until the socket
  next turns readable (karr k38) — after a query cancelled in flight, a
  teardown under a statement, a stopped listen watch. Caller outcome,
  retirement and "late answer not read" do not wait for it.
- **IOAsync: the read handler is not reentrant** — a `->get` in a callback run
  from a poll dies when that handle turns readable again (`… is already done
  and cannot be ->done at Future/IO/Impl/IOAsync.pm line 88`). That is every
  **synchronous statement from the callback of a statement on the same
  connection**: pinned always, pooled whenever the pool hands the same
  connection out again, and so every synchronous statement of a `txn_do` block
  (rolled back). Also a `listen` channel callback that blocks while the next
  notification arrives. Chained (`select_async(...)->then`, `txn_do_async`) it
  works; so does the blocking form on the built-in implementation (`t/26`).
  No card of its own: noted on karr k38, decided with karr k37.

## Connection / AccessBroker

The skeleton inherits the AccessBroker hooks (`set_access_broker` /
`current_access_broker_connect_info`) from core `DBIO::Storage`; `connect_info`
has the same broker-vs-direct branch as the drivers.

With a broker attached, core's per-spawn provider (`_conninfo_provider`) calls
`_async_broker_conninfo` for every new connection — each pool spawn, and a
driver's listen connection — so rotated credentials reach the next one. The base
implements it (karr k27); a `future_io` adapter inherits it. It asks the broker
anew each time and reads three answer shapes:

- **DBI form** `[ 'dbi:…', $user, $password, \%attrs ]` (Vault, HostBound over
  it): the DBIO-private attributes (`async`, `quote_names`, the storage options)
  are stripped, a fifth `\%extra_attributes` joins `\%attrs`, `pool_size` is
  dropped.
- **Connection parameters** — a hashref with a `dbname` and no `dsn` (Static,
  HostBound over it): `dbname` / `host` / `port` become the DSN, `user` /
  `password` the user and password, every other key a DBD attribute. The DSN is
  built by the owning sync storage (`_owner_storage`, its
  `_dsn_from_connect_params`), which alone knows the DBD; a backend without an
  owner croaks, naming the fix. A `dbname` that starts with `dbi:` is the whole
  DSN and needs no owner; `host` / `port` are never DBD attributes there either,
  and a non-empty one beside it croaks, naming the keys (karr k44).
- **The transport's own connect info** — a hashref with a `dsn`, or a
  `[ \%conninfo, \%opts ]` pair: taken as it is.

The first two reach the driver's `_normalize_conninfo` as the DBI form
`[ $dsn, $user, $password, \%attrs ]` — exactly what a direct connect with a
DSN hands it, so the driver needs no broker branch of its own. Any other answer
croaks naming its shape: types and hash keys, never the values, which carry the
password. Without a broker attached the hook croaks `… has no AccessBroker
attached to ask for connect info` (karr k43) — the provider outlives a broker
detached through `clear_access_broker`.

DBD attributes given beside the broker (`connect($broker, \%options)`) are
merged into `\%attrs` of the first two shapes, a setting given in both places
having to agree. Core keeps them empty unless the transport declares
`broker_connect_options`; this base does not, a driver that does gets the merge
from here. Beside a transport's own connect info they croak rather than be
dropped.

## Dependencies

`Future`, `Future::IO` (built-in impl is a `select` loop) and core `DBIO`; no event
loop is a hard require, and the DBDs are the driver's concern. The requirement
lives in this dist's cpanfile, so a sync-only driver pulls no async deps.
Implementation notes for those changing the dist: skill `dbio-async-core`.
