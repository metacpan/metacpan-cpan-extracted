# ADR 0056 — LISTEN/NOTIFY is a core async contract: core owns the machinery, transports fill seams

- Status: accepted
- Date: 2026-09-26
- Tags: async, listen, notify, contract, transport, seams, self-healing, fork-safety, amends-0017, builds-on-0030, follows-pipeline

## Context

ADR 0017 blessed *native escape-hatch methods on Storage* and named
PostgreSQL's `listen` / `unlisten` / `notify` on `DBIO::PostgreSQL::EV::Storage`
as one of its two precedents: driver-owned, prefixed by origin, documented as
non-portable. Core carried only croaking stubs for `listen` / `unlisten` on
`DBIO::Storage::Async` and no `notify` at all. So LISTEN/NOTIFY existed on one
transport (`ev`) and on no other; the `future_io` transport for PostgreSQL
(`DBIO::PostgreSQL::Storage::Async`) states outright that it does not carry it.

Three things changed that picture.

1. **Maintainer decision, 2026-09-26.** LISTEN/NOTIFY becomes part of the core
   async contract. `future_io` and `ev` implement the *same* contract,
   standardised once in `DBIO::Storage::Async`. The family direction is
   Future::IO rather than EV, so the feature cannot stay an `ev`-only extra.
2. **A consumer needs more than LISTEN.** The first consumer is a daemon that
   listens on one channel. It needs the connection to heal itself when the
   database restarts, and a public way for a watchdog to ask whether listening
   is alive and to force a rebuild. Today it reads private slots
   (`$storage->{_listen_pg}`) of one transport — the opposite of a contract.
   The `ev` implementation does not reconnect at all: a dead listen connection
   `warn`s once and stays dead.
3. **The hard part is transport-neutral.** What makes listening robust — the
   channel registry, one dedicated connection, serialising channel operations
   on it, reconnect with backoff, re-subscribing every channel, fork safety —
   has nothing to do with libpq. dbio-postgresql-ev k15 is the evidence: a
   second `listen` raced the first LISTEN's reply on the same connection and
   lost the subscription; the fix was a serialising queue, written for one
   transport. Every other transport would have to rediscover it.

A fourth input arrived while this was being decided: MySQL/MariaDB has no
LISTEN/NOTIFY, and both MySQL transports (`future_io` in dbio-mysql, `ev` in
dbio-mysql-ev) will emulate it with a notify table and timer polling. The
contract therefore has to fit a transport that has no socket to watch.

## Decision

LISTEN/NOTIFY is a **core async contract**. The public surface and the
transport-neutral machinery live in `DBIO::Storage::Async`
(`lib/DBIO/Storage/Async.pm`, section *LISTEN / NOTIFY*). A transport fills
named **listen seams** that croak until provided. This is the pipeline
precedent one level over: `pipeline` orchestrates and the `_pipeline_*` seams
croak by default; here `listen` and its siblings orchestrate and the `_listen_*`
seams croak by default.

### 1. Public contract

| Method | Contract |
|---|---|
| `listen($channel, $cb)` | Register `$cb` and subscribe. Returns a Future that resolves once the subscription is in effect (subscribed *and* watched), and fails if the attempt carrying it fails. A second `listen` on a registered channel replaces the callback and sends no second subscribe. |
| `unlisten($channel)` | Drop the callback and unsubscribe. The last channel going stops watching and closes the connection. Returns a Future. Unknown channel: no-op. |
| `notify($channel, $payload)` | Returns the transport's Future. The payload is a bind value only; `undef` means none. |
| `listen_alive` | Boolean: connection present, fully set up, and the transport's probe says alive. A failing probe is a death report: healing starts and the method returns false. |
| `listen_reconnect` | Force an immediate rebuild (for an external watchdog): close, open, re-subscribe every channel, re-arm, hook. Cuts a pending backoff short and restarts the backoff. Returns a Future for this attempt. |

Callback order is fixed: `$cb->($channel, $payload, $sender_pid)`.
`$sender_pid` is the transport's sender identity — the PostgreSQL backend pid,
or what an emulating transport records (MySQL: `CONNECTION_ID()`); it may be
`undef`.

### 2. Capability gate

`listen`, `unlisten`, `listen_alive` and `listen_reconnect` require `listen` in
`transport_capabilities`; `notify` requires `notify`. Without it they throw the
text core has always thrown, `LISTEN/NOTIFY not supported by this storage
driver` — now as a `DBIO::Exception` naming the public method, and before any
state is created or any seam is called. The gate is by capability *name*, not
by seam probe (unlike `_pipeline_refusal`, karr k218, which probes whether
`_pipeline_enter` is overridden): the decision recorded on k219 fixes it that
way, and a declared name is what an emulating transport can honestly state
about itself.

### 3. Hooks

Two per-instance `simple` accessors on the async backend:

- `on_listen_error` — `$cb->($storage, $error)` for **every** error the
  machinery meets: a lost or dead connection, a failed connect or reconnect
  attempt, a failed subscribe/unsubscribe, a dying channel callback, a failed
  close. Where a Future was handed out for the same operation it carries the
  error too; the hook is the one place that sees all of them. Without a hook
  the error is `warn`ed — never dropped.
- `on_listen_reconnect` — `$cb->($storage)` after the connection has been
  **rebuilt** (self-healing or `listen_reconnect`), every channel re-subscribed
  and watching re-armed. Not called for the first connection.

Storage-first, like the `on_connect_call` coderefs, so both hooks have the same
`($storage, @detail)` shape. They are set on the backend
(`$schema->storage->async->on_listen_error(...)`), **not** as connect
attributes: a connect attribute would have to pass the sync storage's
connect-info split and the DBIO-private strip list, which requires a matching
accessor on `DBIO::Storage::DBI` for each name
(`_dbio_storage_option_names` in `lib/DBIO/Storage.pm`) — a wider surface than
one consumer needs. Adding them as connect attributes later is additive.

The backoff bounds are `inherited` accessors, `listen_backoff_initial`
(default 1 s) and `listen_backoff_max` (default 30 s): attempt *n* waits
`min(initial * 2 ** (n - 1), max)`. A transport class may set its own defaults;
an instance may override them.

### 4. Machinery in core

- **One dedicated listen connection** per storage, outside the pool, shared by
  every channel. Opened by the first `listen`, closed by the last `unlisten` or
  by `disconnect`.
- **Channel registry** — one callback per channel — and dispatch in contract
  order. A notification for an unregistered channel is dropped; a dying
  callback is reported and delivery continues.
- **Serialised channel operations.** Every subscribe and unsubscribe runs
  through one queue per connection, one at a time. No transport ever sees two
  channel operations in flight on the listen connection. This is the k15 fix,
  generalised.
- **Self-healing.** Death is detected three ways: the transport reports it
  (`_listen_lost`), `listen_alive`'s probe fails, or a channel operation fails
  and the probe then says the connection is gone. The sequence is fixed:
  take the dead connection out of the listen state → report through
  `on_listen_error` → stop watching and close it → wait the
  backoff → open → subscribe **every** registered channel → re-arm watching →
  `on_listen_reconnect`. A failed attempt schedules the next with a doubled
  delay; healing stops only when it succeeds, the last channel is unlistened,
  or the storage disconnects. A superseded attempt (a forced rebuild overtook
  it) is recognised by a generation counter; the connection it still hands
  over is closed on arrival.
- **Refused subscription on a live connection.** When a subscribe fails and
  the probe says the connection is alive, the database rejected *the
  statement* (a bad channel, a permission). That channel is dropped from the
  registry and its Future fails; there is no reconnect. Reconnecting would
  only reproduce the rejection, forever.
- **Fork safety.** The listen state records the pid that created it. In any
  other process core never touches the connection: no subscribe, no probe, no
  unwatch, no close — not from `disconnect`, not from `DESTROY` at global
  destruction. A child that calls `listen` starts with an empty registry and
  opens its own connection. This mirrors `DBIO::Storage::DBI::_verify_pid` and
  `DBIO::Storage::PoolBase::_teardown_belongs_here`.
- **Lifecycle.** `disconnect` (and so `DESTROY`, and a `connect_info`
  reconfigure) ends listening: connection closed, registry cleared, pending
  backoff abandoned, waiting Futures failed.

### 5. The seams

Each croaks until a transport provides it. Core calls them only in the opener
process. A seam documented as returning a Future may return a plain value when
its work is already complete; core takes that as an already-resolved Future.

| Seam | Transport obligation |
|---|---|
| `_listen_open` → Future of `$conn` | Open a **new** connection, not from the pool, with current connect info (fresh broker credentials), **fork-safe** (DBD::Pg: `AutoInactiveDestroy => 1`). `$conn` is opaque to core. |
| `_listen_close($conn)` | Close it; must tolerate an already-dead connection. Watching has been stopped first. |
| `_listen_subscribe($conn, $channel)` → Future | Subscribe one channel. Quote or validate the channel at this seam (ADR 0017 §3). May be local-only on an emulating transport. |
| `_listen_unsubscribe($conn, $channel)` → Future | The inverse, same obligations and freedom. |
| `_listen_watch($conn)` | Start delivering: call `_listen_dispatch` per notification in arrival order, `_listen_lost` on death. A throw counts as death. |
| `_listen_unwatch($conn)` | Stop: no dispatch or lost report for `$conn` after it returns. A transport with nothing to stop overrides it empty. |
| `_listen_probe($conn)` | Synchronous liveness probe; false or a throw means dead. |
| `_listen_delay($seconds)` → Future | The backoff timer — core has no event loop. Must resolve asynchronously, from the loop; core cancels it when the wait is cut short. |
| `_notify_send($channel, $payload)` → Future | Send one notification; payload as a bind value only; any connection (typically pooled). |

Two methods run the other way, **transport → core**:
`_listen_dispatch($channel, $payload, $sender_pid)` delivers one notification;
`_listen_lost($conn, $error)` reports death. Both are ignored outside the opener
process, and `_listen_lost` is ignored for a connection that is no longer the
current one.

### 6. Watching is the transport's choice — no core poll mode

`_listen_watch` does not presuppose a readable fd. A **socket-driven**
transport watches the socket, drains pending notifications and watches again
(PostgreSQL over Future::IO: poll `pg_socket`, drain `pg_notifies`). A
**timer-driven** transport emulates: wait a poll interval (through its own
`_listen_delay`), query rows newer than its high-water mark in the subscribed
channels, deliver them in order, wait again; a failed poll query is
`_listen_lost`. Both fit the same seam set, and subscribe/unsubscribe may be
local bookkeeping for the emulation.

Core does **not** ship a poll mode of its own. What it would add is a loop of a
few lines; the high-water mark, the query and the notify table are entirely
transport-specific, and a second path in core would have to be kept in step
with the socket path for no shared logic. Liveness and self-healing apply to an
emulation unchanged.

An emulating transport **may declare** `listen` and `notify`, provided its POD
states the delivery semantics: latency is the poll interval, and a
notification becomes visible when the transaction that wrote it commits — the
same on-commit delivery PostgreSQL gives.

## Conflict with ADR 0017 — surfaced, not blended

ADR 0017 files LISTEN/NOTIFY as a **driver-owned, non-portable escape hatch**:
its Decision point 1 names `DBIO::PostgreSQL::EV::Storage`'s `listen` /
`unlisten` / `notify` as a precedent, point 2 lists "the PostgreSQL protocol
verbs `listen`/`notify`/`copy_in`" as an escape-hatch family, point 4 requires
them to be marked non-portable in POD, and its scope boundary says "the
PostgreSQL native ops are owned by dbio-postgresql-ev".

This ADR takes LISTEN/NOTIFY **out** of that category. It is now portable
async API with a core-owned contract, not an engine exit. The two positions
cannot both hold, so this one — the more recent, maintainer-decided one —
replaces 0017 *for LISTEN/NOTIFY only*:

- 0017 points 1, 2 and 4 no longer apply to `listen` / `unlisten` / `notify`.
  They are not escape hatches and are not marked non-portable.
- 0017 **§3 keeps applying**, carried into this contract at the seam: the
  channel is quoted or validated by the transport in `_listen_subscribe` /
  `_listen_unsubscribe`, and the notify payload travels only as a bind value
  through `_notify_send`. Core passes both through untouched; a transport that
  interpolates either unescaped is a security defect against 0017 §3.
- Everything else 0017 governs is unchanged: `copy_in`, the `duckdb_*` and
  `quack_*` families, and the pattern itself for the next native feature.

0017 is not rewritten; it carries a dated addendum pointing here.

## Rationale

- **One machinery, many transports.** Reconnect, re-subscribe, backoff,
  serialisation and fork safety are the difficult part, and none of it touches
  the wire. Written once, every transport gets it and every fix lands
  everywhere. Written per transport, each gets its own k15.
- **The pipeline shape was already proven here.** Core-orchestrates /
  transport-fills-seams is how `pipeline`, `txn_do_async` and `_run_crud`
  already work; a transport author meets no new pattern.
- **The timer is a seam because core has no loop** (ADR 0014: core carries no
  event-loop dependency). The probe is synchronous because `listen_alive` is a
  boolean a watchdog asks, and a dedicated idle connection can afford a
  synchronous check.
- **`listen`'s Future reports the attempt, the hook reports the stream.** A
  daemon awaiting `listen(...)->get` at startup learns immediately that the
  database is down; the registration stays and healing continues, which the
  hook logs. A Future that silently waited across retries would hang startup
  with no signal.

## Consequences

- **No contract-version bump.** ADR 0024 versions five base classes —
  `DBIO::Introspect::Base`, `DBIO::Diff::Base`, `DBIO::Deploy::Base`,
  `DBIO::SQLMaker`, `DBIO::Storage::DBI::Capabilities`. `DBIO::Storage::Async`
  is not one of them; `t/test/12_contract_version.t` is untouched.
- **Nothing breaks for an overriding transport.** A transport that overrides
  `listen` / `unlisten` / `notify` wholesale (dbio-postgresql-ev today) wins,
  and none of the machinery runs. Core's `listen_alive` then knows no
  connection and answers false, and `listen_reconnect` finds nothing to
  rebuild — so such a transport must answer those two itself or migrate. That
  is a migration state, not a supported design.
- **The old refusal survives.** `t/test/09_async.t`'s class-method
  `DBIO::Storage::Async->listen(...)` still throws the same text; no other test
  in the family matched it.
- **`disconnect` does more.** It now ends listening as well; `DESTROY` and a
  `connect_info` reconfigure reach it when listen state exists.
- **Pinned by** `t/test/38_async_listen_contract.t`: a fake transport over
  `DBIO::Test::Future` drives the gate, the registry and dispatch order, the
  shared connection, serialisation, unlisten, the full healing sequence, the
  backoff bounds and reset, the probe, `listen_reconnect`, stale reports and
  superseded attempts, refused and dead subscriptions, dying callbacks, `notify`,
  `disconnect`, an overriding transport, the `$schema->storage->async` path,
  and the fork guard (explicit `disconnect` and global destruction in a child,
  traced to a file).
- **Deliberately left out:** jitter on the backoff, a maximum attempt count
  (a daemon wants to heal forever; `unlisten` or `disconnect` ends it), hooks
  as connect attributes (§3), a core poll mode (§6), and any replay of
  notifications missed while the connection was down — NOTIFY is not durable,
  and `on_listen_reconnect` is where a consumer re-reads state.

## Future architecture work (tracked cross-repo, not here)

- **dbio-async k22** — the Future::IO-generic seams: `_listen_delay` via
  `Future::IO->sleep`, and a socket-watch loop over `_await_readable` that a
  concrete adapter's drain plugs into.
- **dbio-postgresql k77** — the PostgreSQL `future_io` seams: dedicated DBD::Pg
  connection with `AutoInactiveDestroy`, quoted `LISTEN` / `UNLISTEN`,
  `pg_notifies` drain, `SELECT pg_notify($1, $2)`, a probe; then declare
  `listen` and `notify`.
- **dbio-postgresql-ev k43** — move `DBIO::PostgreSQL::EV::Storage` off its
  `listen` / `unlisten` / `notify` overrides onto the seams; its
  `_dispatch_listen_queue` serialiser becomes core's queue.
- **dbio-mysql / dbio-mysql-ev** — the notify-table emulation (§6), filed
  separately.

## Addendum 2026-09-26 — the Futures callers get await through the transport; watching starts at the call

Implementing the `future_io` seams (dbio-async k22, ADR 0005 there) turned up
two defects in the machinery above (karr core k222).

**1. A pending listen Future could not be awaited.** `listen` and
`listen_reconnect` handed out a Future core built with `future_class->new`, to
settle later. For `future_io` that class is plain `Future`, which knows no
event loop: pending, its `get` dies with "is not yet complete and does not
provide ->await". So `listen(...)->get` worked only while the open and the
subscribe completed synchronously. That is exactly the call the Rationale above
has a daemon make at startup, and the first consumer (dbio-postgresql k77) makes
it. `unlisten` handed out its queue Future, which was derived from the
transport's Futures only through Future.pm's `then` shortcut (a ready Future's
`then` returns the callback's Future unchanged); a `future_class` whose `then`
always derives a Future of its own class gave a non-awaitable one there too.

**2. Watching was marked after the watch, not at it.** `_listen_op_arm` set
`watching` only once `_listen_watch` had returned. A transport that delivers
from inside `_listen_watch` (the first drain of notifications the client
library buffered during the subscribe) could run a callback that unlistens the
last channel or forces a rebuild, and core then closed the connection without
unwatching it. dbio-async had to put its first drain a loop tick later to
avoid that. A `_listen_lost` from inside the watch fared worse: after the
healing path had closed the connection and scheduled a reconnect, the arm step
went on to mark the state `up` and reset the backoff counter.

### Decision

1. **A Future handed to a caller is made from the transport's own Futures.**
   Every Future a listen seam returns passes through `_listen_seam_future`,
   which now keeps the last **pending** one, weakly, as the prototype
   (`proto` in the listen state). `listen`, `unlisten` and `listen_reconnect`
   still build and settle their own Future. When that Future is still pending
   on return, the caller gets `$proto->new` instead, and core settles it from
   its own through a retained `then`. `$f->new` on an instance is the Future.pm
   idiom for a new pending Future of the same kind. It is how Future.pm itself
   derives a Future, and it carries the class and whatever the class keeps
   (an `IO::Async::Future` keeps its loop). The caller's `get` therefore awaits
   by running the loop the seams resolve on. A Future that is already ready
   goes out unchanged.

   - *Pending only*, because a pending Future is one the transport's loop has
     yet to settle, which makes it evidence of the kind that can wait. A ready
     one proves nothing about that.
   - *Weakly*, because only its kind matters. A pending Future that nothing
     holds could never be settled anyway, and a strong reference would add a
     cycle through the state: the seam Future's callbacks close over the state.
   - *Built after the work starts, not before*, because on the first `listen`
     no transport Future exists until the open has been called, and a
     synchronously completing open, subscribe and arm still needs a target to
     settle.
   - **No new seam, no renamed seam.** A seam such as "give me a pending
     awaitable Future" was considered and not added. `Future::IO` has no public
     constructor for a loop-bound pending Future, so each transport would have
     to fake one, while the seams already hand core Futures of the right kind
     at every step.
   - **One contract refinement on the existing seams.** A pending Future a
     listen seam returns must answer `new` called on the instance with a
     pending Future that core can `done` and `fail`. Every `Future` subclass
     does. `DBIO::Test::Future::new` now works on an instance too.
   - Where the transport's Futures cannot await, the caller's cannot either,
     and nothing changes. That is `ev` today: plain `Future->new` settled from
     EV::Pg callbacks, whose callers drive the loop themselves.

2. **The connection is watched from the moment `_listen_watch` is called.**
   `_listen_op_arm` sets `watching` before the call, so anything that closes
   the connection from inside it unwatches it first. After the call, the arm
   checks whether its attempt is still current. A callback or a death report
   during the watch may have ended or replaced the attempt; whatever did so
   owns the state, and the arm stops there. An error the watch threw is still
   reported in that case. A watch that threw on a current attempt resets
   `watching`, because it started nothing to stop, and fails the attempt as
   before.

### Consequences

- No public API change and no seam added or renamed. The `_listen_watch` and
  listen-seam POD and `DBIO::Manual::AsyncStorage` state the two refinements.
  No contract-version bump: `DBIO::Storage::Async` is not one of ADR 0024's
  versioned bases.
- The "also surfaced" point in dbio-async ADR 0005 is answered on the core side.
  dbio-async may now run its first drain inside `_listen_watch` instead of one
  tick later, but nothing requires it to.
- Pinned by `t/test/38_async_listen_contract.t`. A fake transport there resolves
  every seam on a later tick of a fake loop through Futures that can await, over
  `DBIO::Test::Future` and over real Future.pm when it is installed. The
  file checks `listen`, `unlisten` and `listen_reconnect` with `->get`, the
  failure path, and the watch order: an unlisten and a death report from inside
  `_listen_watch`, and a throwing watch. `t/test/31_test_future.t` pins the
  instance `new`.

## Addendum 2026-09-26 — a transport reports a non-fatal error through `_listen_error`

The first timer-driven transport (dbio-mysql k54, the notify-table emulation of
§6) met an error the contract had no place for. After each poll it prunes
delivered rows from the notify table, and that cleanup can fail while the
connection stays perfectly usable. It is not a death, so `_listen_lost` is
wrong: that would close a working connection and heal for nothing. But it must
reach the consumer the way every other listen error does (§3): through
`on_listen_error`, `warn`ed without a hook, never dropped. Core had exactly that
logic, in the private `_listen_report`, and no documented way for a transport
to reach it. dbio-mysql therefore copied it as `_mysql_listen_report`, and
dbio-mysql-ev k44 would have copied it a second time (karr core k227). Two
copies of the reporting rules drift from core the first time core changes them.

### Decision

A third transport → core method joins `_listen_dispatch` and `_listen_lost`:

| Method | Contract |
|---|---|
| `_listen_error($error)` | Report an error that does not end the listen connection. Core hands `$error` to `on_listen_error` exactly as it reports its own: verbatim without a trailing newline, `warn`ed when no hook is set, `warn`ed if the hook dies. It changes nothing else: the connection stays, no reconnect is scheduled, no Future is settled, `listen_alive` answers as before. Ignored when this process has no listen state: a forked child that has not listened itself, or after listening has ended. Returns nothing. |

It is a new name that delegates to `_listen_report`, not `_listen_report`
published under its own name, for two reasons:

- **The helper stays core's.** `_listen_report` is the funnel for every error
  core itself meets, a dying `on_listen_reconnect` hook and a failed close
  among them. Publishing it would freeze an internal helper's name and shape
  as a transport contract. The seam is the transport-facing half only, and core
  may restructure its funnel behind it.
- **The seam carries its siblings' guard; the helper cannot.** A transport's
  callbacks are about the listen connection, and that connection belongs to
  the opener process (§4). `_listen_dispatch` and `_listen_lost` are ignored
  in any other process; `_listen_error` is ignored under the same condition as
  `_listen_dispatch`, so an inherited watcher in a forked child neither reaches
  the child's hook nor touches the parent's state. Adding that guard to
  `_listen_report` would change behaviour for its existing callers; putting it
  on a new method changes none.

The name follows the seam family (`_listen_*`) and mirrors the hook it feeds:
the transport calls `_listen_error`, the consumer receives `on_listen_error`.
It takes no `$conn`. A non-fatal report changes no state, so unlike
`_listen_lost` it has nothing to protect from a stale connection. A late report
about a replaced connection is still a true report.

### Consequences

- No existing caller changes: every internal path still calls `_listen_report`,
  and the reporting rules are unchanged. No public method and no croaking seam
  is added; a transport that never has a non-fatal error calls nothing new. No
  contract-version bump: `DBIO::Storage::Async` is not one of ADR 0024's
  versioned bases.
- The `DBIO::Storage::Async` POD (`_listen_error`, the listen-seam summary,
  `on_listen_error`, the timer-driven watch) and `DBIO::Manual::AsyncStorage`
  (*THE LISTEN/NOTIFY SEAMS*) state the seam.
- Pinned by `t/test/38_async_listen_contract.t`. The file checks that the hook
  receives the error, that it is warned without a hook and when the hook dies,
  that the connection stays up (nothing closed, probed or rescheduled,
  `listen_alive` true, an in-flight `listen` still pending, delivery going on),
  that a report is ignored when nothing is listened to, and that a forked
  child's report touches neither the child's hook nor the parent's connection.
- Follow-ups, on the transports' own boards: dbio-mysql drops
  `_mysql_listen_report` for `_listen_error`, and dbio-mysql-ev k44 uses the
  seam from the start. Both need a core that ships it.
