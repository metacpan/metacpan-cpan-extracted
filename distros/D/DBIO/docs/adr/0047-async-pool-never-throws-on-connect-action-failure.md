# ADR 0047 — Async pool never throws on connect-action failure; failed connection is retired

- Status: accepted
- Date: 2026-09-09
- Tags: async, pool, error-handling, future, cross-driver, family-policy

> Accepted with the implementation committed in karr k109 (2026-07-26,
> commits 79ef141e8 + c85d20eeb; the latter moved the entry from Fixes to
> Breaking Changes because the rule is observable on the public async API).

## Context

Every other failure on an async path in DBIO arrives as a **failed Future**:
query errors, connect timeouts, transaction failures, deploy errors, pipeline
errors. The whole async API teaches the caller to handle errors with `->on_fail`
/ `->then`. The exception is `DBIO::Storage::PoolBase::_acquire_slot` and the
replay path of `DBIO::Storage::Async::_run_crud`'s spawn:

- `_acquire_slot` spawns the connection synchronously, and
- `_run_crud` calls the runner without a `Future->call` wrapper.

The consequence: when a pooled connection's `on_connect_do` /
`on_connect_call` is refused by the server (the user's session setup rejects
on the server side — `search_path` to a role the user doesn't own, a
`SET TIME ZONE` against a value the parameter check rejects), the exception
escapes **before any Future exists**. A caller writing

    $storage->select_async(...)->on_fail(sub { ... })

has no `->on_fail` to reach: the exception left the call before the Future
came back. Callers would need a defensive `eval` around every `*_async` call
to be safe, which defeats the point of the Future-based API.

Second, smaller consequence: the failed connection is already pushed onto
the pool's `_connections` before the replay runs, so it stays counted against
`max_size` even though it was never handed out and never will be. A pool
whose connect actions keep refusing leaks slots and eventually starves.

## Decision

**The async pool never throws on connect-action failure.** Every error that
arises between `acquire` and "I have a connection ready to issue SQL" surfaces
as a failed Future, exactly like every other failure on the async path. And
the connection whose connect actions failed is **retired**: deregistered from
`_connections`, best-effort `_shutdown_connection`d, and its slot returned to
the pool's budget — it is not counted against `max_size`.

Concretely, in `DBIO::Storage::PoolBase`:

- `_acquire_slot` wraps the spawn path so the connect-action failure is
  converted with the house convention — `$self->future_class->fail(...)`, the
  same path `txn_do_async` / `pipeline` / `deploy_async` use. No
  `Future->call` wrapper: `->fail` is enough and is what the rest of core uses.
- `_spawn_connection` wraps the connect-action replay. On failure, the
  connection is **retired** (deregistered from `_connections`,
  `_shutdown_connection`d, `_clear_connection_ready`d). The `on_disconnect_*`
  actions do **not** run — they belong to a session that built up state, and
  here the state never built up; what failed was the connect actions, not a
  session tear-down.
- A new private `_retire_connection` implements the deregister /
  shutdown / clear steps. `on_disconnect_*` deliberately not invoked.

`_run_crud` needed **no** change. Every other async error path already runs
inside a `->then` callback, and `Future->then` converts a thrown exception
into a failed Future automatically; `_acquire_slot` was the only spot outside
every Future. A blanket `eval` around `_run_crud` would have silently caught
programmer errors (`Unknown CRUD operation`, SQLMaker misuse) as failed
Futures, which is exactly the inconsistency the rule exists to remove.

One expected behaviour change: the `_create_connection is a required hook`
check in `t/storage/pool_base.t` used to assert
that `acquire` **throws** the `Subclass must override _create_connection`
message; it now asserts that `acquire` returns a failed Future with the same
message, and that `->get` on that Future re-throws the same message. Throwing
on some spawn failures and failing on others was exactly the inconsistency
the ADR removes.

## Rationale

The Future-based API is a deliberate seam (ADR 0014, ADR 0030): a single
return shape, a single error path, one place to put `on_fail`. The escape
hatch where exceptions leaked past the seam was an oversight, not a design —
every async caller in the family writes `on_fail`-style error handling, and
there is no public API in core where the escape hatch is part of the contract.

The "convert to a failed Future, don't throw" choice is consistent with the
rest of the seam: `txn_do_async`, `pipeline`, `deploy_async`, the bind-lifetime
rules (ADR 0044), the result-set pinning rules (ADR 0045). All of them turn
errors into failed Futures so the caller has one error-handling story to
learn.

The slot-leak fix is independent but lives in the same change because the two
issues share the path: spawn → connect actions → ready (or fail). Retiring
the connection on failure keeps `max_size` honest. Without it, the "no
throw" rule would still leak slots on every connect-action rejection and the
pool would become a slow-motion denial-of-service against itself.

Not running `on_disconnect_*` on retirement is the conservative call: those
actions are for tearing down session state that the connection built up
during its life, and the connection whose connect actions failed never lived
a session. Running them would mean inventing session semantics for a
connection that was rejected before any of the session existed, and would
also mean the connect actions could fail twice — once because they rejected,
once because the disconnect-side cleanup tried to undo something that was
never set up.

## Consequences

- `acquire` returns a failed Future on connect-action failure, never throws.
  Callers may rely on `->on_fail` to cover this case without an `eval`
  around the call site.

- A pool of size `max_size = N` that sees all `N` connect actions rejected
  reports `size == 0` and `available == 0`, and the next `acquire` resolves
  normally once the failure source clears. `max_size` is the upper bound on
  connections the pool *holds*, not on connections it *tried and discarded*.

- A driver that wants `on_disconnect_*` to run when its connect actions fail
  has to opt in: it overrides `_retire_connection` and runs them itself.
  There is no automatic double-fire because the base implementation does not
  run them. This is by design — see Rationale.

- One existing test changed expectations: the `_create_connection is a
  required hook` check in `t/storage/pool_base.t` asserts
  the failed-Future shape, not the throw. New tests in
  `t/storage/pool_connect_actions.t` (36 assertions, mock-only, no event loop)
  pin both halves of the contract: a rejected connect action makes
  `select_async` live and return a failed Future with a greppable `on_fail`,
  and three failed acquires on `size => 2` leave `size == 0` and
  `available == 0`, then the next `acquire` resolves.

- `dbio-async`'s ticket k8 follows: the section-8 of `t/10-on-connect-replay.t`
  that encoded the throw with a comment ("if core changes this, update in
  lockstep") moves to `throws_ok`-on-failed-Future, and the slot count
  assertion lands.

## Future architecture work (tracked cross-repo, not here)

`dbio-async` ticket k8 is the follow-up. It is owned by that repo; the ADR
records the rule, the implementation lives here, the test surface update
lives there.

## Addendum 2026-09-27 — a connection reported dead is retired on release

The Decision above retires a connection whose connect actions failed. That is
the one death the pool could see by itself. A connection that dies later -- the
server drops the session, the socket closes, the protocol falls out of step --
it could not: its only per-connection health signal is the readiness Future of
`_connection_ready_future`, which resolves once, when the connection first
comes up, and stays resolved. `release` therefore put a dead connection back on
the idle list and the next `acquire` handed it to a caller whose query failed
the same way; in a pool of one, every later caller's did (found in
dbio-mysql-ev, karr core k230).

### Decision

The death is reported to the pool by whoever sees it, through one method on
`DBIO::Storage::PoolBase`:

| Method | Contract |
|---|---|
| `_mark_connection_dead($conn)` | Report that `$conn` must never be handed out again. Checked out: nothing happens yet, and the holder releases as always; `release` then retires it through `_retire_in_use_connection` instead of idling it, so a caller queued for its slot gets a freshly spawned connection. Idle: retired at once through `_retire_connection`. Not held by the pool (already retired, never the pool's, dropped as inherited across a fork), or after `shutdown`: nothing happens. Idempotent; returns nothing. |

The caller is the transport: its query path on a connection-level error, or a
connection error callback. The mark is a weak reference to the connection, so
it neither keeps a dropped connection alive nor outlives it, and cannot land on
a later connection that reuses the address; retiring the connection clears it.

### Rationale

- **Report, not probe.** Only the transport can tell a connection-level error
  from a query error the session survives, and the transports disagree on how
  it shows. A borrow-time probe would cost a round trip, or an `is_connected`
  every transport would have to implement truthfully; neither is needed when
  the code that saw the error says so.
- **Retire on release, not on report.** A checked-out connection has a holder,
  and every holder already has exactly one hand-back (ADR 0044's release
  callback, the transaction finalizer). The report does not add a second one;
  it changes what the one hand-back does. So a transport adds a single call
  next to the release it already makes, and a report that comes early, twice,
  or from a callback that cannot know whether the connection is still out is
  harmless.
- **The slot goes on.** Retirement reuses `_retire_in_use_connection` (karr
  k231) rather than `_retire_connection`, because a checked-out connection's
  slot is what a queued caller waits for: retiring it without handing the slot
  on would leave that caller pending until some unrelated release came along.
- **Core does not infer death from a connection error callback.**
  `_create_ready_connection` could mark a connection dead whenever its
  `on_error` fires after connect. For EV::Pg that is exact (`on_error` fires on
  connection loss only), but EV::MariaDB also delivers secondary-statement
  errors of a multi-statement query through `on_error`, where the connection
  lives on. Which errors are fatal is the driver's knowledge, so the driver
  calls the seam.

### Consequences

- `release` changes only for a connection reported dead. A connection nobody
  reported is idled or handed to a waiter as before; nothing in core reports a
  death yet, so no existing path changes behaviour.
- Until a driver calls the seam, its dead connections are reissued as before.
  The follow-ups belong on the transports' boards: dbio-postgresql-ev (its
  pool's `on_error` after connect, the query-callback errors of a lost
  connection), dbio-mysql-ev (the connection-level errors of its executor) and
  dbio-async (the Future::IO adapters' connection errors).
- No contract-version bump: `DBIO::Storage::PoolBase` is not one of ADR 0024's
  versioned base classes. The method is private by name, like the other
  transport-facing pool seams (`_retire_connection`,
  `_create_ready_connection`), and documented in the PoolBase POD and in
  `DBIO::Manual::AsyncStorage`.
- Pinned by `t/storage/pool_dead_connection.t`: a connection reported dead is
  never handed out again and the next acquire gets a fresh one, a queued caller
  gets a fresh one, an idle one is retired at once, reports about connections
  the pool does not hold or after shutdown change nothing, a mark does not
  outlive its connection, a healthy release is unchanged, and a transport that
  reports from its query path gets the caller's next query onto a fresh
  connection.

## Addendum 2026-09-27 — re-examined: core still does not report a death from `on_error` (karr k237)

A dbio-postgresql-ev run proposed that `_create_ready_connection` call
`_mark_connection_dead` from the connection's `on_error` itself, so that no
driver needs an `on_error` wrapper of its own. The addendum above had rejected
that. Re-examined against the three transport families as they are today, the
rejection stands.

### What each transport's `on_error` means

- **EV::Pg** (dbio-postgresql-ev): `on_error` fires on a failed connect and on
  connection loss, and on nothing else. The driver's `_new_connection` wraps the
  `on_error` core passes in and reports the death unconditionally (its k49).
  That is exact, and it sits at the seam core documents for it: the wiring
  hands `_new_connection` its callbacks, and the transport may wrap them.
- **EV::MariaDB** (dbio-mysql-ev): `on_error` fires on a failed connect, on an
  unusable socket right after connect, and for a failed secondary result of a
  multi-statement query, where the session lives on. A connection lost in the
  middle of a query fails that query's callback and never reaches `on_error`.
  Its `is_connected` answers whether a handle exists and is not connecting, not
  whether the session is alive. Reporting from `on_error` would retire live
  connections and still miss every real death.
- **`future_io`** (dbio-async's `DBIO::Async::Pool` and the adapters in
  dbio-postgresql and dbio-mysql): poll-shaped. It has no `on_error` and does
  not build its connections through `_create_ready_connection`. The PostgreSQL
  adapter reports a death from its query path (dbio-postgresql k79).

### Decision

Unchanged: `_create_ready_connection` does not report a death. Neither shape of
the proposal is transport-independent:

- reporting on every `on_error` after connect is wrong for EV::MariaDB;
- asking the handle's `is_connected` from inside `on_error` is not a health
  check on EV::MariaDB, and on EV::Pg it runs before the handle tears the
  connection down (EV::Pg emits `on_error`, then cleans up), so it depends on
  libpq having marked the connection bad by then on every path;
- a class flag saying "`on_error` means death" would have exactly one user
  (EV::Pg), which already has the exact behaviour in the seam meant for it.

Which errors end a session stays the transport's knowledge, and the transport
calls `_mark_connection_dead`.

### Consequences

- No code change. `t/storage/pool_ready_wiring.t` (block 3) pins the rule: a
  connection whose `on_error` fires after connect is released and handed out
  again.
- The follow-ups of the addendum above remain the transports' own. Neither
  MySQL transport reports a dead connection yet -- dbio-mysql-ev, and the
  `future_io` adapter in dbio-mysql. For EV::MariaDB it has to happen on the
  query path, where a lost connection shows.

## Addendum 2026-09-27 — an optional borrow-time liveness seam for idle connections (karr k241)

The first addendum made the pool retire a connection someone *reported* dead,
and rejected a borrow-time probe: "Report, not probe". That covers every death
somebody sees. It does not cover a connection that dies while it sits idle on a
transport that nobody watches while idle. On the poll-shaped transports --
`future_io` (dbio-async's `DBIO::Async::Pool` with the PostgreSQL and MySQL
adapters) and, per the second addendum, EV::MariaDB -- no code reads an idle
connection's socket, so the report comes only from the caller whose query the
dead connection failed (found in dbio-postgresql k79). And the common causes of
an idle death -- a server restart or failover, an idle timeout on the server or
on a proxy in between, an administrator's kill -- rarely take one connection:
after a restart every idle connection is dead, and `_acquire_slot`, handing out
the oldest idle connection first, gives each of them to one caller whose query
then fails. A pool of ten fails ten calls before it recovers.

EV::Pg is the exception: its loop watches the idle socket, its `on_error` fires
on connection loss, dbio-postgresql-ev reports the death (its k49), and the
idle connection is retired at once -- as long as the loop ran in between.

### Decision

`DBIO::Storage::PoolBase` gets one optional seam, **`_idle_connection_alive($conn)`**,
asked by `_acquire_slot` about each idle connection before it is handed out.

| Answer | What the pool does |
|---|---|
| true | hands the connection out, as before |
| false | retires it (`_retire_connection`) and tries the next idle connection; with none left, spawns a fresh one or queues the caller, as for an empty idle list |
| throws | as false, and the error goes to the pool's `on_error` |

- **The default answers true without looking.** No check and no cost: a
  transport that does not override it behaves exactly as before.
- **No round trip.** An override answers from local state, or from a
  non-blocking read of what the server has already sent -- the close or the
  error a server sends when it ends an idle session. It runs on every borrow of
  an idle connection, so it never blocks and never sends anything.
- **Idle connections only.** A freshly spawned connection has just come up, and
  one handed straight from `release` to a queued caller was in use a moment ago.
- **The skip is the point.** The existing per-borrow hook,
  `_connection_ready_future`, can already refuse a connection, but a refusal
  there *fails the acquire* (`_retire_readiness_failure`) -- the caller still
  gets an error, only earlier. The new seam instead lets `acquire` go on to the
  next connection, so the caller never sees the dead one.

### Rationale

- **Why not "deliberately not":** the cost argument against a probe was a round
  trip on every borrow. A check that needs no round trip costs a method call by
  default and a non-blocking read where a transport fills it -- small next to
  the statement that follows, which is a round trip anyway. The benefit is
  largest exactly where it hurts: a restart turns into zero failed calls
  instead of one per pooled connection.
- **Why it does not replace the report:** the check narrows the window, it does
  not close it. A connection can die between the check and its first
  statement, or die without the server saying so (a network partition sends
  nothing); that statement fails, and the transport reports it through
  `_mark_connection_dead` as before. Retrying a failed statement on another
  connection -- what the sync storage's reconnect does -- is a different,
  riskier decision (was it executed before the connection went?) and is not
  taken here.
- **Why optional, not required:** only the transport knows what it can learn
  without a round trip, and for an EV::Pg pool the answer is already given by
  the loop. Core cannot write a correct default check for any transport.
- **Why a throw is reported:** a check that always throws would retire every
  idle connection and turn every borrow into a spawn -- a pool that silently
  stops pooling. `on_error` (which warns by default) makes that visible.

A caution for the transports: DBD::Pg's `pg_socket` alone does **not** show an
idle death. libpq notices that the server closed the connection only when it
next reads the socket; until then `PQsocket` and `PQstatus` report a good
connection (k79 saw `pg_socket == -1` only *after* a failed call). A
PostgreSQL check has to read first -- `PQconsumeInput`, which DBD::Pg runs in
`pg_notifies` -- and then look. Whether one read is enough, when the server
sends a FATAL message before it closes, is for the driver to settle against a
live server.

### Consequences

- No behaviour change for any pool that does not override the seam; the seam
  is private by name like the other transport-facing pool seams, and
  `PoolBase` is not an ADR 0024 versioned class, so no contract bump.
- Pinned by `t/storage/pool_idle_liveness.t`: the default does not check; a
  connection the seam does not vouch for is retired and the caller gets a
  fresh one; with every idle connection dead one acquire clears them all; a
  live one behind a dead one is handed out without a spawn; a throwing check is
  retired and reported to `on_error`; the seam is asked about idle connections
  only.
- Follow-ups belong on the transports' boards:
  - **dbio-async**: `DBIO::Async::Pool` overrides `_idle_connection_alive` to
    ask its owning storage (the adapter), with a storage-side default of true,
    the way it already delegates `_create_connection`.
  - **dbio-postgresql**: the `future_io` adapter answers it with a
    non-blocking read then a look (`pg_notifies`, then `pg_socket`), verified
    against a live server killing an idle backend.
  - **dbio-mysql**: the `future_io` adapter answers it -- an idle MySQL
    connection's socket has nothing to read unless the server closed it or
    sent an error, so a zero-timeout readability check is one candidate.
  - **dbio-mysql-ev**: the same, if EV::MariaDB exposes the socket.
  - **dbio-postgresql-ev**: optional -- its loop already reports idle deaths;
    a check would only help when the loop has not run since the death.

## Addendum 2026-09-28 — a queued caller's Future: made by the transport, withdrawn by its caller (karr k255, k256)

A caller that finds every connection checked out, with the pool at
`max_size`, is queued: `_acquire_slot` pushes a pending Future -- its *waiter*
-- onto `_waiters`, and the next `release` settles it with the freed
connection. Two things about that Future turned out to belong to the
transport, and one thing about the queue turned out to be wrong.

- **The queue lost connections (karr k255).** `release` and
  `_retire_in_use_connection` handed the connection to the head of the queue
  whatever state its waiter was in. A caller that cancels its Future cancels
  the waiter too -- Future.pm carries a cancel down the `->then` chain -- and
  `done` on a cancelled Future.pm does nothing: the connection was neither
  borrowed nor idle, and in a pool of one every later acquire hung. A waiter
  settled by somebody else refused `done` and `release` died (found in
  dbio-async k29).
- **The waiter's class is the class of the whole wait (karr k256).** Every
  `->then` off a pending Future is made with that Future's own `new`, so the
  waiter's class decides the class of the Future `acquire` returns, of the
  query chained off it, and of the Future a blocking call finally `->get`s.
  Core made it `future_class->new`, a plain Future by default, whose `get`
  while pending croaks *is not yet complete and does not provide ->await*.
  dbio-async's blocking wrappers (ADR 0001 there) died that way whenever the
  pool was busy for a millisecond (its k30). Reaching the waiter took a
  pool-wide `future_class` switch plus a wrapper around `_acquire_slot`.
- **A transport has to be able to give up on a waiter (karr k256).**
  dbio-async refuses a blocking wait that can never end (a blocking call inside
  the block of the transaction that holds the last connection). Failing the
  waiter is not enough: it has to leave the queue, or the next release hands
  it a connection nobody takes. With no core method it grepped `_waiters`
  itself.

### Decision

| Where | Contract |
|---|---|
| `release`, `_retire_in_use_connection` | Hand a connection only to a waiter still pending. A waiter that `is_ready` -- cancelled, or settled from outside -- is dropped from the queue on the way (`_next_waiter`). No live waiter: `release` idles the connection, `_retire_in_use_connection` spawns nothing. |
| `_new_waiter` (seam) | Called by `_acquire_slot` once per queued caller, and only then. Returns a new, **pending** Future answering `is_ready`, `then`, `done`, `fail`. Default `$self->future_class->new`. It only makes the Future: the pool queues it, wires the cancel hook, and settles it. It may mark the Future (a back-reference to the pool, held weakly). A seam that dies, or answers anything but a pending Future, fails the `acquire` -- with its error, or naming the class and `_new_waiter` -- and queues nothing; `acquire` never throws. |
| `_withdraw_waiter($waiter)` | Remove `$waiter` from the queue so no release or retire hands it a connection. Returns 1 if it was queued, 0 otherwise. Does **not** settle it: the caller does -- typically `fail` with its reason, which reaches the caller's Future through the chain. |
| cancel hook | A waiter whose class answers `on_cancel` (Future.pm and subclasses) is withdrawn by the pool the moment it is cancelled, also when the caller cancels its own Future. The hook holds the pool and the waiter weakly. DBIO::Test::Future cannot be cancelled and is not wired. |

### Rationale

- **Skip at hand-out and withdraw on cancel -- both.** The withdraw keeps the
  queue exact at the moment a caller leaves; the skip is what makes a waiter
  settled without a withdraw harmless, and covers a Future class that can be
  cancelled but offers no `on_cancel`. Either alone leaves a way to lose a
  connection.
- **A seam, not `future_class`.** Only the waiter waits: every other Future the
  pool makes is handed out ready. A transport that needs a loop-aware Future
  needs it there, and switching `future_class` for the whole pool reached the
  waiter only by accident of it being made with that class.
- **Core queues and wires, the seam only makes.** So an override cannot forget
  the queue or the cancel hook, and never has to call the default.
- **Withdraw does not settle.** The one caller that withdraws today fails the
  waiter with a message only it can write; a cancel has already settled it.
  Settling inside the withdraw would have to guess a message.
- **Validated like `_seam_future` (karr k252).** A ready "waiter" would be
  queued, skipped by the next release and returned to the caller as if it had
  been served -- with a value that is no connection.

### Consequences

- No behaviour change for a caller that does not cancel and a transport that
  overrides nothing, beyond `release` no longer dying on, and no longer losing
  a connection to, a waiter that stopped waiting.
- Not covered: cancelling an acquire while it waits for a *new* connection to
  become ready. Future.pm carries that cancel into the pool's registered
  readiness Future and the connection is lost the same way; it is not a
  waiter, and is noted on karr k256 for a card of its own.
- `PoolBase` is not an ADR 0024 versioned class; both methods are private by
  name like the other transport-facing pool seams, documented in the PoolBase
  POD and in `DBIO::Manual::AsyncStorage`. No contract bump.
- Pinned by `t/storage/pool_cancelled_waiter.t` (k255) and
  `t/storage/pool_waiter_seam.t` (k256), each against DBIO::Test::Future and,
  when installed, Future.pm.
- Follow-ups on dbio-async's board (k29, k30): drop the TODO in its t/25
  section 6; override `_new_waiter` instead of wrapping `_acquire_slot`; call
  core's `_withdraw_waiter` instead of its own.

## Addendum 2026-09-28 — cancelling an acquire that waits for a new connection to come up (karr k258)

The k255/k256 addendum above left one case Not covered: cancelling an
`acquire` while it waits not in the queue but for a *new* connection to become
ready. `acquire` spawns a connection when the idle list is empty and the pool
is below `max_size`, then gates it on `_connection_ready_future`; it returned
`$ready->then(...)` to the caller. Future.pm's `_sequence` wires
`$fseq->on_cancel($ready)`, so a caller that gave up -- a cancel, a `wait_any`
timeout -- cancelled the pool's registered readiness Future. The connection,
counted against `max_size`, then came up to a cancelled readiness Future that
settled nothing, was never idle and never handed out; in a pool of one, every
later `acquire` waited for a slot that never freed (found by the k256 worker,
reproduced against Future.pm 0.52; karr core k258). The same path ran when
`_retire_in_use_connection` handed a fresh spawn to a queued waiter (the
`->then` off the waiter adopted `$ready->then` and cancelled it in turn).

### Decision

| Where | Contract |
|---|---|
| `acquire` (connection not yet ready) | Hands the still-connecting connection to its caller through a Future of the caller's own -- `_hand_over_when_ready` -- never through a `->then` off the readiness Future. The readiness chain is held by the pool, keyed by the caller's Future, until it settles; the caller's Future is of the class a `->then` off the readiness Future would have been. Cancelling the caller's Future does not cancel the readiness Future. |
| readiness resolves | The connection goes to the caller if it still waits; if the caller gave up, it goes where `release` sends a returning connection -- to the next waiter still waiting, or back to idle. |
| readiness fails | The connection is retired (`_retire_connection`), and the failure reaches the caller if it still waits. |
| `shutdown` (outside global destruction) | A caller still waiting for a connection to come up -- whose readiness Future the shutdown loop did not fail, because it is the transport's own seam Future, not one registered for a connection the pool holds -- is failed here all the same, and the held readiness chain is cancelled where its class can be. |
| a callback dies in the hand-over | The hand-over runs under the `->then` off the readiness Future, which would turn the death into the failure of a Future nobody reads. It is reported through the pool's `on_error` instead (and warned, if `on_error` dies in turn) -- a callback on the caller's Future, or on that of the waiter `release` hands the connection on to. |
| `_verify_pid` in a forked child | The inherited hand-overs are dropped with the rest, unsettled: a connect that completes in the child resolves none of the parent's callers there. |

### Rationale

- **A caller's Future, not a `->then` off readiness.** The bug was structural:
  Future.pm carries a cancel down a `->then` chain, so any Future the caller
  could cancel, chained off the readiness Future, would cancel it. The fix
  gives the caller a separate Future and keeps the readiness chain on the
  pool's side of the seam, out of the caller's cancel reach -- the same shape
  the k255/k256 addendum used to keep a queued waiter's cancel from losing a
  connection.
- **A given-up caller's connection is not dropped.** When the caller gave up,
  the connection still comes up; routing it through `release` reuses the exact
  hand-on the queue already has (next waiter, else idle), so `max_size` stays
  honest and no slot leaks -- the failure mode this ADR exists to prevent.
- **Retire, don't idle, on a readiness failure.** A connection whose readiness
  failed never lived a session, the same reasoning as the Decision at the top
  of this ADR; `_retire_connection` keeps `max_size` honest without running
  `on_disconnect_*`.
- **Shutdown lets go of the held chain.** The pool holds the readiness chain
  for the caller; `shutdown` is the one place that has to fail a caller the
  connection loop cannot reach and drop the chain it was holding.

### Consequences

- The "Not covered" note in the k255/k256 addendum is closed: cancelling an
  acquire that waits for a new connection no longer loses the connection, in a
  pool of one or any other.
- A caller that does not cancel is served as before: a ready readiness Future
  still takes the fast `->then` path, and a caller that waits to the end gets
  its connection, or the connect's error. Three things it can observe did
  change. A callback of its own that dies as the connection is handed over no
  longer dies into whoever settled the readiness Future -- the transport's
  `on_connect` / `on_error` -- but is reported through the pool's `on_error`.
  `shutdown` now fails a caller waiting on a readiness Future the pool never
  registered; before, the connection loop could not reach it and it waited for
  good. And a forked child no longer resolves a caller it inherited when the
  connect completes there.
- `shutdown`'s cancel of the held chain is, with Future.pm, a cancel of the
  readiness Future it was chained off. A transport whose
  `_connection_ready_future` returns a Future of its own sees that Future
  cancelled at shutdown, and no longer sees it cancelled when a caller gives
  up -- its connect runs on. `PoolBase`'s POD for the seam says so.
- `PoolBase` is not an ADR 0024 versioned class; `_hand_over_when_ready` is
  private by name like the other transport-facing pool seams, and the
  `_ready_handovers` register is internal state reset on `_verify_pid`. No
  contract bump.
- Pinned by `t/storage/pool_acquire_cancel_readiness.t`: a pool of one whose
  acquire is cancelled while the connection is still coming up frees the slot
  when the connection arrives -- the next acquire gets it, or the caller
  already queued does; a readiness that fails after the caller gave up retires
  the connection; the same for a fresh spawn `_retire_in_use_connection` handed
  to a queued caller; a caller that waits to the end still gets its connection
  or the error; `shutdown` fails a caller still waiting and closes the
  connection once, for a registered readiness Future and for the transport's
  own, and a readiness that settles afterwards changes nothing; a forked child
  settles nothing it inherited; a dying callback is reported; nothing warns.
  Mock-only; the cancel cases against Future.pm, the rest against
  DBIO::Test::Future as well.
- Not covered, each on a card of its own:
  - A readiness that fails while a second caller is queued behind the
    connecting connection retires the connection and leaves that caller
    waiting -- `_retire_connection` does not touch the queue. This predates
    k258 and does not depend on a cancel (karr k260).
  - A connection retired through `_retire_connection` while it is still coming
    up, without its readiness Future being settled, stays held by the
    hand-over register until `shutdown`; before k258 it was freed once its
    caller let go (the k235 property). No driver in the family retires a
    connecting connection that way. And a forked child that drops an inherited
    hand-over whose readiness Future is the transport's own makes Future.pm
    carp *lost a sequence Future* if that Future is settled in the child
    (karr k261).
  - dbio-async's poll-driven readiness Future is no longer cancelled by a
    caller that gives up, and is cancelled by `shutdown`; that seam has not
    been run against this change (karr dbio-async k36).

## Addendum 2026-10-04 — a connection that fails to become ready hands its slot on (karr k260)

The k258 addendum left one case Not covered that needs no cancel. `acquire`
spawns while the pool has room, so in a pool of one the first caller waits for
its connection to come up and the second is queued behind it. When that connect
failed, the pool retired the connection through `_retire_connection`, which
leaves the queue alone -- it was written for connections "never handed to a
waiter". The first caller got the error; the second stayed queued in a pool
that held no connection, with nobody left to release one (found by the k258
worker, karr core k260). The same happened when the readiness seam refused a
connection a `release` had just handed to a queued caller, with another caller
queued behind it.

### Decision

| Where | Contract |
|---|---|
| readiness fails: a connection still coming up (`_hand_over_when_ready`), or a seam that answers a failed Future or dies (`_retire_readiness_failure`) | The connection is retired through `_retire_in_use_connection`: closed once, no `on_disconnect_*`, and its slot goes to the oldest caller still waiting, on a fresh spawn. The caller whose connection failed gets that error, as before. |
| `_retire_in_use_connection`, the replacement spawn dies | The waiter it was made for fails with the spawn's error, as before. The slot is still free, so the next waiter gets the next attempt -- until one is served or nobody is queued. Before, every caller behind the first stayed queued. |
| a callback dies as the slot is handed on | Reported through the pool's `on_error`, like every other death in a hand-over (k258). The caller whose connect failed still gets its error. |

### Rationale

- **One rule for a slot somebody waits for.** A caller is queued for a slot, not
  for a connection. Whether the connection in that slot was checked out (k231)
  or still coming up makes no difference to the caller behind it, so both leave
  through the same method.
- **A fresh spawn, not the first caller's error.** The queued caller gets the
  attempt it would have had, had it come first. With the server down, each
  queued caller fails with the error of its own attempt, one after the other;
  the pool retries nothing on its own.
- **`_retire_connection` stays as it is.** What still calls it directly has no
  waiter to serve: an idle connection (nobody is queued while one is idle), a
  spawn whose connect actions were refused (its caller handles the error), and
  `shutdown`.

### Consequences

- With nobody queued nothing changes: the connection is retired, nothing is
  spawned, the next `acquire` spawns on demand.
- `shutdown` is unchanged. `_retire_in_use_connection` does nothing once the
  pool is shut down, and `shutdown` closes the cold connection itself, once.
- k258 and k235 stand: the caller still waits on a Future of its own, and a
  retired connection is let go of by the pool.
- The first Not covered item of the k258 addendum is closed. The other two
  (karr k261, karr dbio-async k36) are not touched.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/storage/pool_readiness_failure_waiter.t` -- a pool of one, the
  connect failing with one and with two callers queued, the replacement failing
  to connect or to spawn, the seam refusing a handed-on connection by a failed
  Future and by dying, callers that gave up, a dying callback -- and, for the
  spawn that dies with two waiters queued, by `t/storage/pool_retire_in_use.t`.
  Mock-only, against DBIO::Test::Future and Future.pm.

## Addendum 2026-10-04 (II) — shutdown knows a connection still coming up by its hand-over (karr k262)

`shutdown` runs the owning storage's `on_disconnect_*` against a connection
that reached readiness and none against a cold one. It told the two apart by
the readiness table alone (`_connection_ready_lookup`), and that table knows
only a readiness Future registered through `_create_ready_connection`. A
readiness Future the transport makes itself, in a `_connection_ready_future`
of its own -- dbio-async's poll -- is not in it. A connection still coming up
behind one looked ready to `shutdown`, which ran the disconnect actions against
it: a blocking statement on a connection that is not connected yet (karr core
k262, from karr dbio-async k36).

### Decision

| Where | Contract |
|---|---|
| `_hand_over_when_ready` | The hand-over the pool holds for an `acquire` names its connection -- weakly: the pool's connection list is what keeps a connection alive, the hand-over does not. |
| `shutdown`, per connection | Cold is a connection whose registered readiness Future is still pending, as before, **or** one an `acquire` still waits on (`_hand_over_pending`), whoever made its readiness Future. Either is retired through `_retire_connection`: closed once, no `on_disconnect_*`. Every other connection runs its disconnect actions and is closed, as before. |

### Rationale

- **The pool already knew.** An `acquire` waiting for a connection to come up
  is exactly what the k258 hand-over records; it only did not say for which
  connection. No new seam and nothing for a transport to declare.
- **Whoever made the Future.** The rule in ADR 0030 §5 is about the
  connection, not about where its readiness Future is kept. A transport that
  gates readiness in a seam of its own gets the same shutdown as one that
  registers it.

### Consequences

- A connection that came up is unchanged: idle or checked out, its hand-over
  is settled and gone, and it gets its disconnect actions.
- Cold in the same way: a connection whose caller gave up while it was coming
  up, a fresh spawn handed to a queued caller, and an idle connection the
  transport's seam answers a pending Future for when it is borrowed again.
- Global destruction is the exception. `shutdown` settles nothing there, and
  what tells a cold connection from a ready one -- the readiness Future, the
  hand-over -- may be freed ahead of the pool; the disconnect actions can then
  run against a connection still coming up. The `shutdown` POD says so; the
  absolute wording in ADR 0030 §5 holds outside it.
- The hand-over holding its connection only weakly leaves karr k261 as it was:
  what keeps a retired connection alive there is the chain, not this.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/storage/pool_shutdown_coming_up.t`, against DBIO::Test::Future
  and Future.pm; the caller that gave up against Future.pm only.

## Addendum 2026-10-04 (III) — a pool size that is no positive integer is refused (karr k270)

The pool's size comes from outside: the `pool_size` connect attribute, or a
`pool_size` in an AccessBroker's answer, handed to `PoolBase::new` as `size`.
A size the pool cannot be -- negative, no number, a fraction -- became its
`max_size` as given. `acquire` spawns while the pool counts fewer connections
than `max_size`, so with `-1` or `'abc'` it never spawned: every `acquire` was
queued for a release nobody could make, with no error at connect or later.

### Decision

| Where | Contract |
|---|---|
| `PoolBase::new`, `size` | A size that is false -- not given, `0`, `''` -- is the default of 5, as before. Any other has to be a positive integer, as a number or a string of digits. Anything else throws a `DBIO::Exception` saying what a size has to be; a value that is no number is not quoted. No pool is built. |

### Rationale

- **A pool that never spawns serves nobody, and said nothing.** `acquire`
  neither threw nor failed there -- it queued. The constructor is the one place
  the size can be reported.
- **`new` throws, `acquire` still never does.** `new` already croaks without
  `conninfo`; the rule of this ADR is about `acquire`, which is unchanged.
- **`0` stays the default.** It has meant "not given" all along, in `PoolBase`
  and in the family's transports. Whether it should be refused instead is not
  decided here.

### Consequences

- The same refusal reaches a `pool_size` in the connect info of an async
  storage, or in a broker's answer, when the storage builds its pool.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/storage/pool_size_edge.t`, against DBIO::Test::Future and
  Future.pm.

## Addendum 2026-10-08 — a spawn holds its slot, and a shutdown from inside `acquire` is final (karr k277)

`acquire` reads the pool's books -- an idle connection, room for a new one, or
the queue -- and acts on what it read. In between it calls code that is not the
pool's: the `conninfo_provider` (an AccessBroker's answer), `_transform_conninfo`,
`_create_connection` and the owning storage's connect actions in a spawn;
`_idle_connection_alive` and `on_error` before an idle connection is handed
out; `_new_waiter` before a caller is queued; `_connection_ready_future` before
a connection is handed over. The pool looked for a shutdown once, on the way
in, and counted a connection only once it existed. Code that came back into the
pool from one of those places -- a Vault client that runs the event loop while
it fetches, a transport that reports an error from its constructor, an
`on_error` that disconnects the storage -- found books `acquire` had already
read (found in karr k270, groups 4 and 5):

- an `acquire` made while the provider answered saw the same room and took the
  same slot: two connections in a pool of one;
- a pool shut down from inside got its connection all the same. `shutdown` had
  run before the connection existed, so nothing ever closed it, and the caller
  held a connection of a pool that no longer took it back;
- the same through `_retire_in_use_connection`, whose replacement spawn runs
  with its waiter already off the queue: a shutdown from inside resolved that
  waiter with a connection, and a waiter that gave up meanwhile -- a cancel, a
  timeout -- lost the replacement, which was neither borrowed nor idle;
- a connection whose connect actions died after a caller had been queued behind
  it left that caller waiting for a release nobody was left to make.

### Decision

| Where | Contract |
|---|---|
| `_spawn_connection` | The spawn takes its slot before it calls anything: the pool has room while its connections **plus its spawns in flight** are fewer than `max_size`. The slot becomes the connection when `_create_connection` returns, and is given up when anything before that dies -- "a spawn that failed took no slot" (k260) stands. |
| `acquire` made from inside a spawn | Finds the slot taken. With no other room it is queued behind the spawn, asks the provider nothing, and is served by the next `release`. |
| a spawn that fails with a caller queued behind it | The slot goes to the oldest caller still waiting, on a spawn of its own, as `_retire_in_use_connection` hands a slot on. A callback that dies there is reported through `on_error`; `acquire` still never throws. |
| pool shut down from inside the provider or `_transform_conninfo` | No connection is made. |
| pool shut down from inside `_create_connection` | The connection is closed through `_shutdown_connection`, once, without `on_disconnect_*`, its readiness bookkeeping cleared, and it is not counted. |
| pool shut down from inside the connect actions | The connection counted by then; `shutdown` closed it with the rest. It is not handed out. |
| pool shut down from inside `_idle_connection_alive`, `on_error`, `_new_waiter` or `_connection_ready_future` | Nothing is handed out, spawned or queued after it. |
| the `acquire` that was in any of those | Fails with `Connection pool has been shut down`, as on any shut down pool. A spawn that died fails it with its own error, shut down or not. |
| `_retire_in_use_connection`, pool shut down from inside the replacement spawn | The waiter the replacement was for fails with `Connection pool has been shut down`, like everyone still queued. |
| `_retire_in_use_connection`, the waiter gave up while its replacement was spawned | It is passed over as `release` passes it over (k255): the replacement goes to the oldest caller still waiting, or to the idle list. |
| `_verify_pid` | Drops the slots of spawns in flight with the rest of the inherited state: a spawn standing in the parent holds nothing in the child's pool. |

### Rationale

- **The cause is one, so the rule is one.** Every case above is the pool acting
  on books it read before somebody else's code ran. The slot is therefore taken
  before that code runs, and the one thing that code can change for good -- the
  shutdown -- is looked for after it, at every place, not at the two that were
  found.
- **A slot, not a placeholder connection.** Transports read `_connections`
  themselves, and `size` is the number of connections that exist. A spawn in
  flight is counted beside them, in a table of its own, and each spawn gives up
  exactly its own entry -- so a give-up that comes twice, or after a fork
  dropped the table, takes nothing from another spawn.
- **Queued, not refused.** A caller that comes in while the last slot is being
  filled is in the position of any caller at a full pool, and is treated like
  one. It also asks the broker nothing: the answer of the moment belongs to the
  connection being opened.
- **The slot of a failed spawn has a caller again.** Before, nobody could be
  queued while the pool had room. Now a caller can be queued behind a spawn, so
  a spawn that fails has to hand its slot on, or that caller waits for a release
  nobody makes -- the k260 defect by another way in.
- **The connection is closed where it is known.** `shutdown` cannot close a
  connection that did not exist when it ran. The spawn that made it is the only
  place that holds it.
- **The spawn's own error stands.** A spawn that died has no connection to
  account for, and its error says more than the shutdown would.

### Consequences

- Without re-entry nothing changes: a spawn's slot is taken and becomes its
  connection within one call, and nobody is queued behind it.
- A caller queued behind a spawn must not wait for its Future, blocking, from
  inside that spawn: the spawn cannot finish first. Before, such a caller got a
  connection beyond `max_size` at once. The EV transports' check for a wait
  that cannot end (`_pg_held_by_callbacks`, `_mysql_held_by_callbacks`) looks at
  the connections the pool holds and does not know a spawn in flight; noted for
  dbio-postgresql-ev and dbio-mysql-ev.
- `_shutdown_connection` is now also called for a connection the pool never
  counted -- the one born into a shut down pool.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/storage/pool_spawn_reentry.t` -- every seam of a spawn, on
  `acquire` and on the replacement spawn; the liveness check, `_new_waiter` and
  `_connection_ready_future`; a waiter that gave up; a fork in flight -- by
  section 9 of `t/access_broker/24-pool-broker-edge-paths.t`, with a real
  `DBIO::Storage::Async` backend and broker, and by section 7 of
  `t/storage/pool_reentrant_callbacks.t`. Mock-only, against DBIO::Test::Future
  and Future.pm; the cancel against Future.pm only.

Not covered:

  - A `release` made from inside `_new_waiter` leaves the caller queued while a
    connection is idle, until the next `release`. Starting the decision over
    would call the seam twice for one caller, against "once per queued caller".
  - A fork from inside a spawn whose child goes on through that spawn, instead
    of leaving it, makes a connection for books the child may have dropped
    meanwhile.
  - A callback that dies as `release` or `_retire_in_use_connection` hands a
    connection on still reaches whoever called it (karr k279).

## Addendum 2026-10-08 (II) — a callback that dies as the pool settles its Future goes to `on_error`, wherever the pool settles it (karr k279)

The pool settles Futures that are not its own. `release` hands the connection
to the oldest queued caller; `_retire_in_use_connection` hands on a fresh spawn,
that spawn's error, or the shutdown; `shutdown` fails everyone still waiting. A
Future runs its callbacks as it is settled, so the code of the caller it
belongs to runs inside the pool method somebody else called. The k258 addendum
sent the death of such a callback to `on_error` where a connection is handed
over as it comes up. Everywhere else it was thrown at whoever had called the
method (found in karr k270, group 5):

- out of `release` and `_retire_in_use_connection`, at the caller handing its
  connection back. Through `_txn_hand_back` that is the chain a transaction's
  own Future is settled by: a transaction the server had committed failed with
  the error of a caller it had nothing to do with;
- out of the loop in `_retire_in_use_connection` after a replacement spawn had
  died: the caller queued behind never got its attempt;
- out of the middle of `shutdown`: the callers behind were left unsettled and
  every connection open, and `shutdown`, being terminal, did nothing when run
  again -- from `DESTROY` included.

### Decision

The k258 row -- "a callback dies in the hand-over" -- holds at every place the
pool settles a Future that is somebody else's:

| Where | Contract |
|---|---|
| `release`, the connection goes to a queued caller | A callback of that caller that dies is reported through the pool's `on_error` (and warned, if `on_error` dies in turn). `release` returns. The connection is that caller's and is not put on the idle list as well. |
| `_retire_in_use_connection`, the waiter gets the replacement, the spawn's error, or the shutdown | The same. After a spawn's error the slot goes on to the next waiter all the same. |
| `shutdown`: a queued caller, a caller waiting for its connection to come up, the registered readiness Future of such a connection | The same, each on its own: `shutdown` goes on, fails everyone else, closes every connection once, and returns. |
| `shutdown` cancels the chain it held for a waiting caller | A callback that dies under the cancel -- an `on_cancel` on the transport's readiness Future -- is reported the same way. |
| the report | Says what the pool was doing: `A callback died as <what>: <error>`. The wording for a connection handed over as it comes up is as it was. |

### Rationale

- **The precedent decides it.** k258 already said where such a death goes, for
  the caller's Future and for "that of the waiter `release` hands the connection
  on to" -- but only when `release` ran under a hand-over. Whether a connection
  reaches a queued caller from a connect that completed or from another
  caller's `release` is nothing that caller, or the one releasing, can tell.
- **The one who called is the wrong one to tell.** It did not make the
  callback, cannot fix it, and has work of its own that the death cut short: a
  transaction's finalizer, the rest of a shutdown. `on_error` is where the pool
  reports what it has no caller for.
- **Each settle on its own.** One guard around a loop would still let the first
  death skip everyone behind it. A caller is failed, or served, whatever the
  callbacks of the one before it did.
- **Nothing is undone.** A Future is settled before its callbacks run, so the
  caller whose callback died has its connection, or its error. The pool does
  not take a connection back because a callback died.

### Consequences

- A callback made with `->then` is not affected, in Future.pm as in
  DBIO::Test::Future: its death is the failure of the Future `->then`
  returned, which its maker holds. Nothing was thrown there and nothing is
  reported. Only a callback a Future runs bare -- Future.pm's `on_done`,
  `on_fail`, `on_ready`, `on_cancel` -- could die into the pool;
  DBIO::Test::Future has none.
- A caller that relied on the death of its own bare callback surfacing at
  somebody else's `release` gets it at `on_error` instead; with the default
  `on_error` that is a warning.
- The last Not covered item of the k277 addendum is closed.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by section 6 of `t/storage/pool_reentrant_callbacks.t` (`release`, the
  caller a retirement serves), by `t/storage/pool_callback_death.t` (a spawn's
  error, a shutdown under the spawn, the four places in `shutdown`, an
  `on_error` that dies in turn, `->then` in both Future classes), and by
  `t/test/48_async_txn_stranger_callback_death.t` (a transaction committed and
  one rolled back, over a real `DBIO::Storage::Async` backend). Mock-only; a
  bare callback against Future.pm only.

Not covered:

  - The readiness Future `_create_ready_connection` registers is settled from
    the transport's own connect and error callbacks. A bare callback somebody
    hung on that Future, dying there, is thrown into the transport's callback,
    and in the error callback the pool's `on_error` is then not told of the
    transport's error. The pool's own chain on that Future is a `->then` and
    unaffected. Guarding it means the wiring's callbacks have to know the pool;
    left for karr k261, which is about that wiring.

## Addendum 2026-10-08 (III) — a hand-over ends when its connection leaves the pool (karr k261)

The k258 addendum made the pool hold, for every `acquire` waiting on a
connection still coming up, a hand-over: the caller's Future, the connection,
and the chain off the readiness Future. It let go of one in two places only --
when the readiness Future settled, and at `shutdown`. A connection that left
the pool any other way left its hand-over standing, and the chain, which
cannot be taken off the readiness Future again, went on acting for a pool the
connection was no longer part of. The k258 addendum left two such cases Not
covered; karr k270 (group 5) executed them and a third, a caller that lets go
of its Future; the k279 addendum left a fourth.

### Decision, point by point

**1. A connection retired while it is coming up** (`_retire_connection`, and
through it `_retire_in_use_connection`).

| Where | Contract |
|---|---|
| the `acquire` waiting for it | Fails then and there, with `Connection was retired while it was coming up`, unless its caller gave up already. Before, it waited until `shutdown` for a connection that was gone. A callback of it that dies is reported through `on_error` (k279). |
| the hand-over | Leaves the register. The pool holds neither the caller's Future nor the connection any more; the connection is freed as soon as no caller holds it. |
| the chain | Stays on the readiness Future with nothing to act for. The pool keeps it, and the readiness Future, until that Future settles or the pool is gone. |
| the readiness Future settles afterwards | Nobody is handed the connection the pool closed, and nothing warns. If it fails, the slot the connection had is offered to the oldest caller still waiting, on a fresh spawn. |
| the queue | `_retire_connection` leaves it alone, as documented; `_retire_in_use_connection` hands the slot on at once. Unchanged. |
| during `shutdown` | None of this: `shutdown` fails every caller with its own error, as before. |

Follows from: k235 -- once the pool lets go of a connection "it is freed as
soon as no caller holds it" -- which k258's register had taken back for this
case; from `acquire`'s own rule that a failure reaches the caller as a failed
Future, where waiting for good is no outcome at all; and from k260 for the
late failure, which already handed the slot on under Future.pm and now does
under both Future classes.

**2. A forked child** (`_verify_pid`).

| Where | Contract |
|---|---|
| an inherited hand-over | Let go of like one whose connection was retired, except that nobody is told: the caller is the parent's, and is dropped unsettled. |
| its chain | Neither cancelled nor forgotten: kept, with nothing to act for, until its readiness Future settles or the child's pool is gone. |
| the readiness Future settles in the child | None of the parent's callers is resolved, the child's pool gets no connection, and Future.pm has no sequence Future to warn of. |
| `shutdown` in the child | Neither cancels such a chain nor fails anybody. |

Follows from k233 and k234: in the child none of the parent's callbacks runs,
and nothing of the parent's is torn down. A cancel would carry into the
transport's readiness Future and run its `on_cancel` -- a callback of the
parent's -- in the child, so the chain is held instead. Forgetting it, as
before, left its closure with the parent's caller in hand: DBIO::Test::Future
resolved that caller in the child, and Future.pm warned of the sequence Future
it had lost.

**3. A caller that lets go of its Future without cancelling it.** Stays as it
is, and is documented: the connection comes up, is handed to a Future nobody
reads, and stays checked out -- counted, never idle. The pool cannot tell such
a caller from one still waiting. Holding the caller's Future weakly would tell
with Future.pm, whose chains hold a Future from its tail, and would free the
Future of every DBIO::Test::Future caller at once, whose chains hold it from
the head only: no rule that holds in both classes, and none without a new
interface. Cancel the Future, as `release` is called once (k270).

**4. A callback on the registered readiness Future that dies as the
transport's connect or error callback settles it** (`_create_ready_connection`,
left by k279). Reported through `on_error`, like every other death as the pool
settles a Future; it does not reach the transport, and the transport's error
is passed to `on_error` all the same.

### Rationale

- **The connection decides, not the Future.** A hand-over exists for a
  connection the pool holds. When the pool stops holding it, the hand-over has
  nothing left to hand over, whatever its readiness Future does later.
- **Emptied, not removed.** Neither Future class can take a `->then` off a
  Future again. What the pool can do is leave the chain with nothing in hand,
  so the chain reaches the caller and the connection only through a state the
  pool empties.
- **Kept until it settles.** Future.pm warns when a chain is gone before its
  Future settles, and that Future may be the transport's own. What is kept is
  the chain, the readiness Future and their callbacks; neither a connection
  nor a caller.
- **`shutdown` empties as well.** A chain it cannot cancel -- a Future class
  without `cancel` -- held the connection for as long as its readiness Future
  lived. It is left with nothing in hand like the others.

### Consequences

- A driver that retires a connection still coming up now fails the `acquire`
  waiting for it. No driver in the family does; they report through
  `_mark_connection_dead`, which retires an idle connection only.
- The hand-over register is keyed by a sequence, no longer by the address of
  the caller's Future, which a parked chain outlives.
- The Not covered item of the k258 addendum for karr k261 is closed, and the
  one the k279 addendum left. The POD of `_create_ready_connection` and
  `_verify_pid`, which named both cases as open, says what holds now.
- `PoolBase` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/storage/pool_handover_open_cases.t`, against DBIO::Test::Future
  and Future.pm: both kinds of readiness Future, a late connect and a late
  failure, a queued caller, a child that shuts down, what the pool still
  holds (the connection's destructor and a weak reference to the caller's
  Future count it), and the two bare callbacks against Future.pm only.

Not covered:

  - A parked chain is kept until its readiness Future settles. One that never
    does stays until the pool is gone -- Futures and callbacks, no connection.
  - Once the pool itself is gone, so are its parked chains: a readiness Future
    of the transport's own settled only then makes Future.pm warn `lost a
    sequence Future`. In a forked child nothing can be done about it without
    cancelling.
  - In global destruction `shutdown` settles nothing and empties nothing, as
    before (k254, and the k262 addendum).

## Addendum 2026-10-08 (IV) — what ends work talks to the pool it began on (karr dbio-async k46)

Shutdown is terminal per pool instance (ADR 0030 §5): a late `release` is a
no-op, and a reconnect builds a fresh pool rather than reviving the old one.
That rule assumes the late `release` reaches the old instance. Core's own
orchestration did not send it there. `txn_do_async`, `pipeline` and
`deploy_async` asked the storage for its pool twice -- once to acquire, and
again, `$self->pool`, when the work ended, to release or retire the
connection. Every transport in the family builds its pool lazily
(`$self->{pool} ||= ...`), in the slot `disconnect` empties. Work that was
under way at a disconnect and ended afterwards -- a transaction standing
between two statements whose coderef went on, a pipeline waiting for its
sync, a DDL statement in flight -- therefore built a **new** pool on the
disconnected storage as it ended, and handed it a connection that pool had
never held. The storage was left holding a pool nobody had asked for. Found
in the dbio-async review (karr dbio-async k46,
"Also found (a)"); that transport had the same shape in its own completions
and fixed it there (dbio-async ADR 0007).

### Decision

- **What begins work resolves the pool and keeps it; what ends work talks to
  that pool.** `pool` is called where a connection is acquired, never where
  one is handed back, retired or reported dead.
- In core: `txn_do_async` hands the pool it acquired from to its finalizer
  (`_finalize_txn_async`, `_txn_hand_back` -- both private, both take the pool
  as a trailing argument now); `pipeline` binds its `$release` and `$retire`
  to it; `deploy_async` releases each pooled run's connection to the pool that
  run acquired from.
- The same rule is the transport's for the connections it acquires itself:
  the `_query_async` pattern in `DBIO::Storage::Async` and in
  `DBIO::Manual::AsyncStorage` hands the pool to `_release_on_ready` along
  with the connection.

### Rationale

- **A connection belongs to one pool instance.** Only that instance counts
  it, and only that instance can take it back. Any other pool refuses it
  (`_holds_connection`), so the release was lost either way -- the new pool
  was pure side effect.
- **Ending is not connecting.** A lazy `pool` is how a storage connects.
  Something that merely finished must not leave a disconnected storage with a
  pool again.
- **Nothing new is held.** The closures that end the work already held the
  storage, and the storage its pool; they now hold the pool directly. The
  pool holds its storage weakly, so no cycle through the storage is closed,
  and the pool is let go of when the work has ended.

### Consequences

- After `disconnect`, work that ends late leaves the storage without a pool,
  and the pool it began on sees the hand-back as the no-op ADR 0030 §5
  describes. The caller's Future ends as before.
- No public interface changes. `_txn_hand_back` and `_finalize_txn_async`
  gained an argument; no driver in the family overrides or calls either.
  `DBIO::Storage::Async` is not an ADR 0024 versioned class. No contract bump.
- Pinned by `t/test/49_async_completion_same_pool.t`, against
  DBIO::Test::Future and Future.pm, with a backend that builds its pool
  lazily: each of the three roads with and without a disconnect, the release
  and the retirement, and -- for the transaction and the pipeline -- that the
  storage and the pool are freed afterwards.

Not covered:

  - `$ctx->pool` on a transaction or pipeline context still asks the storage
    each time (documented there). It is an accessor, not a completion; whether
    it should answer the pool its connection came from is undecided.
  - A `deploy_async` split into several runs asks `pool` as each run begins.
    A later run after a disconnect begins on a new pool. That takes a run
    in flight at the disconnect that still succeeds on its closed connection
    (measured against a fake wire that answers it all the same).
  - The EV transports release through `$self->pool` in their own completions
    (dbio-postgresql-ev, dbio-mysql-ev) -- theirs to change.
  - A backend that has run `deploy_async` is not freed when it is dropped:
    the closures that chain its runs and statements refer to themselves. That
    was so before, is independent of which pool they talk to, and is why the
    test does not assert the freeing for deploys.

    > No longer so. The runs and the statements are chained by a method that
    > calls itself one further on (`_run_ddl_runs_async`,
    > `_run_ddl_stmts_async`), not by a sub that holds itself; a backend that
    > has deployed is freed like any other. The test asserts the freeing for
    > deploys as well, and `t/test/51_async_deploy_nothing_left.t` pins it on
    > every road a deploy takes.

## Addendum 2026-10-09 — a release carries the lease of its borrow (karr k275)

k270 made a second `release` of a connection that is still idle a silent
no-op, and left one case open: the second release that arrives **after** the
connection went on -- handed to a queued caller by the first release, or
borrowed again from the idle list. The pool kept no record of who held a
connection, and the stale release and the holder's own release are the same
call, `release($conn)` with the same object. Taken for the holder's, the stale
one handed the session to a second caller while the first still used it, or
idled it while it was held. Measured in t/storage/pool_double_release.t
(section 2, three cases); an identity per connection could not help, as the
releaser had nothing to present.

### Decision

Maintainer decision 2026-10-09: **the lease is an optional second argument of
`release`.**

- `PoolBase::_lease($conn)` returns the lease of the borrow `$conn` is in:
  an opaque token, stable while the borrow lasts, and a different one for the
  next. The holder asks for it right after its `acquire` resolved.
- `release($conn, $lease)` takes the connection back only when `$lease` is the
  connection's current one. Any other lease -- the borrow ended, the
  connection went on, it was retired -- is a **silent no-op**: no exception,
  no warning, no `on_error`. That is what every release the pool does not take
  already is (a connection it does not hold, the k270 no-op, a release after
  shutdown), and `on_error` would have reversed the k270 claim "says nothing".
- A release **without** a lease behaves as before: taken for the current
  holder's. Nothing that does not pass one changes.
- The borrow ends with the release that is taken, and with the connection's
  retirement; the pool keeps no lease for a connection it has detached, and
  forgets them all in a forked child and at shutdown.
- `DBIO::Storage::Pool`'s contract allows the second argument and does not
  require it: a pool of another class is called with an undef lease.

### Callers

Core's callers take the lease where they acquire and release with it:
`txn_do_async` (kept in the transaction's guard, used by `_txn_hand_back`),
`pipeline`, `deploy_async` (`_hand_back_once`), and
`DBIO::Test::AsyncHarness`. They ask through `_pool_lease`, which answers
undef for a pool that has no `_lease`. The retirement
(`_retire_in_use_connection`) takes no lease: a connection that is retired is
retired.

The transports release themselves and are not changed here: dbio-async
(`_release_on_ready`), dbio-postgresql-ev and dbio-forked. Without a lease
they keep the release-once contract of k270; passing the lease is theirs to
adopt.
