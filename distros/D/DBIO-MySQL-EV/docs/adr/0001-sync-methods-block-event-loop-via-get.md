# ADR 0001 — Sync methods block the event loop via `->get`

- Status: accepted
- Date: 2026-06-21
- Tags: async, future, storage, sync-degrade, drivers
- Corrected: the *mechanism* the Decision states -- that `Future.pm`'s `->get`
  spins the EV loop -- was wrong, and the sync methods died until karr k48 (see
  the Addendum); the decision itself stands

## Addendum (2026-09-26, karr k48) — `->get` never waited; a Future that runs the EV loop does, and refuses a wait that would deadlock

The decision stands: every sync method is its async sibling run to completion,
`return $self->X_async(@_)->get`, one implementation, no second code path. What
was wrong is the claim that made it work. `future_class` was `'Future'`, and
`Future.pm`'s `get` does not know about any event loop: on a pending Future it
calls `await`, which `Future` leaves to subclasses and by default dies with
*"Future=HASH(0x…) is not yet complete and does not provide ->await"* (Future
0.52; `await` exists since 0.44). Every Future of this transport is settled from
the EV loop, by an EV::MariaDB callback, so it is always still pending when a
sync method calls `->get`.

Measured on MySQL 8.0.30 (EV 4.37, EV::MariaDB 0.08) by the new
`t/25-sync-fallback-live.t`: `select`, `select_single`, `insert`, `update`,
`delete`, `txn_do` and `deploy` all died with that message. The die was not
clean either. `Future.pm` holds a sequence Future only weakly, so the caller's
dropped chain took its continuations with it ("lost a sequence Future"): a died
`insert` or `deploy` sent its first statement and never ran the rest of its
chain -- the `LAST_INSERT_ID()`, the remaining DDL, the release of its
connection -- and a later wait in the same process hung until the harness timed
it out. No test had driven the sync path over this transport;
`t/13-async-e2e.t` had even met the croak and worked around it in the test.

**What makes it block now.** `future_class` returns `DBIO::MySQL::EV::Future`,
a `Future` subclass whose only method is `await`: `EV::run(EV::RUN_ONCE)` until
the Future is ready -- the pattern of `IO::Async::Future` and the `Future::IO`
implementations, which `Future.pm` documents `await` for. A new standalone
class; no storage or component class changes its `@ISA`. The class has to reach
every Future a sync method waits on, and does:

- `pool` passes `future_class` to `DBIO::Storage::PoolBase->new`, so acquire,
  waiter and readiness Futures are of that class;
- `DBIO::MySQL::EV::QueryExecutor` builds its query Futures from a
  `future_class` argument (the storage passes its own; the default is the same
  class);
- core's orchestration (`_run_crud`, `txn_do_async`, `deploy_async`) builds
  Futures only from `future_class` or by chaining `->then` on the transport's,
  and `Future.pm`'s `then` on a pending Future and its convergents
  (`needs_all`, …) return an instance of the invocant's class. No core change.

Pinned offline by `t/26-ev-future-mock.t` (EV-timer-driven fake EV::MariaDB;
without the wiring 13 of its 27 assertions fail) and live by
`t/25-sync-fallback-live.t` (each sync method returns what its `*_async`
sibling resolves with, a failure is a die with the operation's error; 28 of 40
fail without the repair).

**Termination.** `EV::RUN_ONCE` blocks until an event arrives, but returns at
once -- and `EV::run` returns false -- when no watcher keeps the loop alive.
`await` croaks then instead of spinning: nothing left in the loop could settle
the Future. A watcher that does keep the loop alive (a statement in flight, the
listen poll timer) keeps `await` waiting, as `IO::Async::Future` would; a
Future nothing will settle then waits as long as that watcher lives. Every
watcher this dist arms only as a guard is `keepalive(0)` (ADR 0010, karr k46)
and does not count.

**Recursion, and where it stops working.** libev runs loops recursively, so a
sync method called from inside a callback of the running loop -- a timer, an
`AnyEvent` or `IO::Async` handler on EV -- works: the nested run serves every
watcher and returns to the callback (verified live, `t/25`). The cost the
Rationale accepts is unchanged; the calling callback is suspended meanwhile.

It does **not** simply work inside a callback of one of this transport's own
connections: a `then` / `on_done` on its Futures, or a `txn_do` /
`txn_do_async` coderef, which runs inside the `BEGIN`'s callback on the pinned
connection. EV::MariaDB's `query` -- the queueable operation, which this
transport uses for every statement without bind values -- only queues while a
callback of the same handle is running (`callback_depth > 0`) and sends once
that callback has returned (or earlier, when another operation on that handle
completes). A blocking call made there that needs such a statement on that
connection waits for a query that is never sent. Statements with bind values
go `prepare` → `execute` → `close_stmt`, exclusive operations that start at
once, and statements on other connections are sent normally -- those
complete. Measured live, before the refusal below existed: inside a then on a
bindless query, with a pool of one, a nested bindless `select` hung and a
bound one returned; in a `txn_do` coderef, `$ctx->select` without a WHERE hung
and `$ctx->insert` returned. Those waits hung without a croak because the
handle's read watcher was still active, so the loop had "work"; where a
preceding exclusive operation had just stopped the handle's watchers -- a
`$ctx->insert` before the `$ctx->select` -- the no-watcher guard fired
instead, with a message that points nowhere near the cause.

**Such a wait is refused, loudly** (maintainer decision on karr k48, option
(b)). `DBIO::MySQL::EV::QueryExecutor` wraps every callback it hands to
EV::MariaDB in a per-connection *frame*: `local`, so it is restored when the
callback returns and when it dies, and nested correctly -- a callback of the
same connection inside another gets a frame of its own, and a callback of
another connection leaves this one's alone. The frame is set at that boundary
and nowhere else, so a Future failed synchronously outside any EV::MariaDB
callback is not in one. A statement without bind values issued on a
connection while one of its frames runs is registered as *held* until that
frame returns or the statement's Future is ready. `DBIO::MySQL::EV::Future`'s
`await` dies while a held statement exists -- on entry and before every loop
iteration, because a statement can be issued while the wait runs -- with
*"Blocking wait refused: …"*, naming the statement and pointing to the
`*_async` methods and `->then`. A top-level wait, or one in a plain EV
callback, never sees a held statement, so nothing changes there. Before dying,
`await` retains the Future it was asked to wait for: `Future.pm` holds a
sequence Future only weakly, and the chain the dying caller drops would
otherwise lose its remaining steps -- an insert's `LAST_INSERT_ID()`, the
release of its connection -- exactly as the unrepaired `->get` did above.

What the refusal is not:

- It cancels nothing. The held statement is still sent once the callback
  returns, so a statement without bind values that writes still writes. In a
  `txn_do` coderef the refusal fails the coderef, and the transaction is rolled
  back, the refused statement with it.
- It is over-strict in one window: while a statement is held, every blocking
  wait until that statement's callback returns is refused, also one that does
  not depend on the statement and would have finished. Accepted.
- It knows only the executor's callbacks -- the ones the transport's Futures
  settle from, and so the ones a `then` chain or a `txn_do` coderef runs in. A
  blocking call from any other callback of a pooled connection (its
  `on_connect`, `on_error`) is not detected and still hangs when it needs a
  statement without bind values on that connection.

The alternative -- settle the executor's Futures outside EV::MariaDB's
callbacks, so that no caller code ever runs while a connection's
`callback_depth` is raised, which would make these calls work instead of
refusing them -- changes the timing of every statement and the settle contract
karr k45 pinned (`t/23-close-stmt-mock.t`). It was karr k51, and was built: see the
addendum of 2026-10-25 below, which replaces this refusal. The POD of
`DBIO::MySQL::EV::Future` (`await`), `DBIO::MySQL::EV::Storage::future_class`,
`DBIO::MySQL::EV::QueryExecutor` and `DBIO::MySQL::EV::TransactionContext`
describes the refusal. Pinned offline by `t/27-blocking-in-callback-mock.t` --
a fake EV::MariaDB that queues as the real one does; without the refusal
every refusal case in it hangs until its watchdog fails it -- and live by
`t/25-sync-fallback-live.t`.

**Corrections to the text below.**

- *Context*: since core ADR 0030 an `{ async => 'ev' }` schema keeps its sync
  DBI storage, and `$rs->all`, `$row->update`, scripts and migrations go through
  that, not through this backend. The sync methods here are reached by code
  that holds the backend itself: `$schema->storage->async`, a directly
  constructed `DBIO::MySQL::EV::Storage`, and the transaction context's
  blocking methods.
- *Decision*: the sync methods are core's `DBIO::Storage::Async` `select` …
  `deploy`, inherited unchanged since the thin-transport refactor (karr k19;
  `t/06-thin-transport-structure.t` pins it), `deploy` included.
  `lib/DBIO/MySQL/Async/Storage.pm:477-505`, `Storage.pm:60` and
  `Storage.pm:473-475` predate that refactor and the rename (ADR 0008);
  `future_class` is `DBIO::MySQL::EV::Storage::future_class`.
  `TransactionContext.pm:71-75` names code this dist no longer has: the
  context's blocking methods are core's
  `DBIO::Storage::Async::TransactionContext` (ADR 0002 amendment, karr k31).
- *Consequences*, last bullet: "`future_class` is the real CPAN `Future` …
  `->get` therefore drives a real EV loop" is the error this addendum corrects.
  The coupling it names is right, and is now what `DBIO::MySQL::EV::Future`
  exists for: the sync methods depend on `future_class->get` blocking.

## Addendum (2026-10-04, karr k53) — a blocking wait for a pooled connection that cannot come back is refused too

The k48 refusal covers a blocking wait for a statement on the **same**
connection. A blocking call in a callback can also need **another** connection
and never get it. `$storage->select` in a `txn_do` coderef runs on a pooled
connection, not on the transaction's; the transaction gives its connection back
only after the coderef has returned and `COMMIT` or `ROLLBACK` has been
answered. With a pool of one -- or with a pool of N and the call nested in N
transactions -- `acquire` queues the caller for a connection that cannot come
back while the caller blocks. No statement is issued, so nothing is *held* and
the k48 refusal does not see it.

The no-watcher guard of `await` does not catch it either, for the reason the
k48 addendum measured: while the callback of a `query` runs, the handle's read
watcher is still active, so the loop has "work" and the wait hangs. Where an
exclusive operation had just stopped the handle's watchers -- a `$ctx->insert`
before the storage call -- the guard does fire, with *"… is pending and the EV
loop has nothing left that could complete it"*, and it leaves the caller in the
pool's queue with its chain dropped: the next `release` hands the connection to
a Future nobody holds, and the pool has lost it. Both outcomes are reproduced
offline by `t/33-blocking-on-exhausted-pool-mock.t` without the refusal; neither
was measured against a server for this addendum.

**Such a wait is refused**, with the same words and to the same end as k48:
*"Blocking wait refused: …"*, naming the size of the pool and what to do
instead -- the transaction context's `*_async` methods chained with `->then`,
the storage's `*_async` methods chained with `->then` for a statement that
belongs outside the transaction, or a larger `pool_size`. `await` refuses when
three things hold, checked on entry, before every loop iteration, and once more
when the loop has run dry:

1. *The Future it waits for is chained off a queued caller.*
   `DBIO::MySQL::EV::Pool::_new_waiter` -- core's waiter seam (core k256) --
   marks the Future a queued caller waits on with its pool, and
   `DBIO::MySQL::EV::Future::new`, called on an instance, carries the mark to
   the new Future: that is how `Future.pm` makes the Future of every `then` and
   the one a convergent returns. The mark is `Future`'s user data (`udata`,
   Future 0.49, this dist's minimum), and holds caller and pool weakly.
2. *Every connection of that pool has a callback of its own on the call
   stack* -- the frame the executor keeps around each callback it hands to
   EV::MariaDB, the k48 mechanism -- and none is idle.
3. *None of them has a statement in flight*: the executor counts, per
   connection, the statements it dispatched whose Future has not settled. A
   statement in flight may be what gives a connection back (a pooled statement
   releases its connection when it is answered), so the wait goes on while there
   is one, and is refused when the last has been answered.

2 and 3 together are sound for the holder that matters: a transaction with a
callback of its connection running and nothing in flight can only end through a
`COMMIT` or `ROLLBACK`, a `query`, which EV::MariaDB does not send before that
callback has returned. Each condition alone refuses waits that would have
ended, and `t/33` has a case that fails for each: a pool that is merely
exhausted, a connection whose callback runs but that still has a statement in
flight, a transaction that holds the only connection while none of its
callbacks runs, and a blocking wait for something else while a call nobody
waits for is queued.

**The refused call does not run.** Unlike a held statement, which EV::MariaDB
already has and which cannot be taken back, a queued caller has no connection
yet. `await` takes it out of the pool's queue
(`DBIO::Storage::PoolBase::_withdraw_waiter`) and fails it; the failure reaches
the waiting Future through its chain, and `get` dies with it. A refused insert
writes nothing. Nothing is cancelled and nothing is retained: the chain ends
with the failure. A call queued for the same connection that nobody blocks on
is not touched and runs once the transaction has ended.

What it does not cover:

- A blocking wait on a Future that reaches a queued caller without being
  chained off it -- a `then` callback that *returned* the Future of a storage
  call, on a Future that was pending before, or a convergent whose first
  component is not the queued one. It waits as before.
- A transaction whose coderef returns a Future that depends on a call queued
  for the transaction's own connection
  (`txn_do(sub { $storage->select_async(...) })`, pool of one). There is no
  blocking wait inside a callback; the transaction waits for the call and the
  call for the connection. Ending that wait needs a bound on `acquire`.
- The callbacks the executor does not hand out (a pooled connection's
  `on_connect`, `on_error`), as for k48.

**The alternative, a timeout on `acquire`**, would end all of these waits,
including the two above -- after the timeout, with an error that says a
connection was not available, not why. It is a new public option whose natural
home is core's `PoolBase`, for every pooled transport, and a caller that hits
it in a transaction coderef has still waited the whole timeout for something
that could be told at once. It is not taken here; the refusal names the cause
at the moment it arises and needs no option. The two do not exclude each
other.

No storage or component class changes its `@ISA`; `DBIO::MySQL::EV::Pool`
gains an override of a seam core provides for this, and
`DBIO::MySQL::EV::Future` a second method of its own beside `await`: `new`
(the k48 addendum's "whose only method is `await`" is as of its date). The POD of
`DBIO::MySQL::EV::Future` (`await`, `new`), `DBIO::MySQL::EV::Pool`
(`_new_waiter`, `_mysql_held_by_callbacks`), `DBIO::MySQL::EV::QueryExecutor`
(`_waits_for_callback`), `DBIO::MySQL::EV::Storage::future_class` and
`DBIO::MySQL::EV::TransactionContext` describes it. Pinned offline by
`t/33-blocking-on-exhausted-pool-mock.t`; `t/27-blocking-in-callback-mock.t`
is unchanged.

## Addendum (2026-10-25, karr k51) — Futures settle from an idle watcher; a blocking wait inside a callback of the transport's own connection returns (replaces the k48 refusal)

Maintainer decision of 2026-10-25: option (c) of karr k48. The k48 refusal is
gone; the k53 refusal (above) stays.

**The change.** `DBIO::MySQL::EV::QueryExecutor::_settle_cb` no longer settles
a statement's Future inside the EV::MariaDB callback that delivered the answer.
It queues the settling (`_defer`) and one `EV::idle_ns` watcher (`_drain`, one
for all connections) runs the queue, oldest first. Only the settling moves: the
wire work stays in the callbacks as before (prepare → execute → `close_stmt`,
issued from the callbacks; the Future settles after the `close_stmt` has been
answered, `t/23-close-stmt-mock.t` holds that and passes unchanged in its
claims). Inside the watcher, in this order: the per-connection counts of
statements in flight and of exclusive operations go down, the Future gets
`done` or `fail` (and with it every `then`, `on_done`, pool release and
transaction step hanging off it), and the statements that wait behind it
(`execute_when_idle`, the pinned `ROLLBACK`) are started. That is the order
the old code had inside the callback, so the ROLLBACK of a failed transaction
still goes out behind the `LAST_INSERT_ID()` an insert reads after its answer
(k74). The counts go down in the watcher, not in the callback, so the window
between the answer and the settling counts as in flight: a statement issued
meanwhile queues behind the waiting ones instead of overtaking them.

What this buys: a `then` on the transport's Futures and the coderef of
`txn_do` / `txn_do_async` (it runs from the settling of the `BEGIN`) now run
with the handle's `callback_depth` at 0. EV::MariaDB sends a `query` issued
there at once, so a blocking wait for it ends. `$ctx->select` without a WHERE
in a `txn_do` coderef, a sync `select` in a `then` with a pool of one: both
return; both died with *"Blocking wait refused"* (k48) before. The per-callback
*frame* and the *held* registry (`Future::_hold`, `_held_statement`, the
refusal text) are removed. The frame survives in one place, where k53 needs it:
`_drain` sets `%FRAME` around each settling, so *"a callback of the connection
is running"* (condition 2 above) now means *a settling of it is running* -- a
`then` chain or a coderef, the code that holds a transaction's connection
until it returns. Condition 3 (nothing in flight) is unchanged. `t/33` passes
unchanged.

Details that are decisions:

- A settling that dies is warned about (`DBIO::MySQL::EV: exception in
  callback: ...`, as EV::MariaDB does for its own callbacks) and does not stop
  the ones behind it; the frame is `local`, so it is restored.
- Entries are taken out of the queue before they run, so a blocking wait inside
  one -- a nested `EV::run`, which runs the watcher again -- carries on with the
  entries behind it and none runs twice.
- A forked child inherits the queue: entries queued by another process are
  dropped (`$$` is checked, as in every callback of the executor, karr k46).
- `forget` bumps a per-handle generation; the settling of a statement answered
  before its handle was forgotten leaves the counts alone (they belong to the
  next handle at that address, karr k82).
- Not covered, as before: a blocking wait inside a callback the executor does
  not defer -- the pool's `on_connect`, `on_error` -- is not changed by this.

**Measured, before and after** (the "before" first: HEAD 7c6fa51 without the
change, run from a clean `git archive`; "after" is this change; MySQL 8.0.30
and MariaDB 11.x in the `dev-dbio` cluster, EV 4.37, EV::MariaDB 0.08, pool of
5 or 1, over the cluster LoadBalancer; the script lives
in the job's scratch space and is not part of the dist). The host was shared and
loaded (load average 6 to 11 at the time, runs niced and CPU-capped by
`capped-test`), so the live numbers are noisy: 3 to 5 rounds, old and new
alternated, ranges below are the spread of the per-round figures.

| Live, per statement (round medians / p99) | MySQL before | MySQL after | MariaDB before | MariaDB after |
|---|---|---|---|---|
| sequential `SELECT 1` (no binds), median | 1.04-1.40 ms | 1.14-1.94 ms | 1.10-1.99 ms | 1.13-1.89 ms |
| same, p99 | 1.7-3.0 ms | 1.5-6.9 ms | 1.9-9.9 ms | 1.5-3.3 ms |
| sequential `SELECT ?` (prepare/execute/close), median | 2.1-3.4 ms | 2.0-3.5 ms | 1.8-4.2 ms | 2.4-3.1 ms |
| `txn_do_async`: BEGIN, 3 chained statements, COMMIT, median | 6.1-10.6 ms | 6.1-8.3 ms | 7.9-11.7 ms | 7.7-10.7 ms |
| `txn_do_async`: 5 plain statements issued at once, median | 5.2-11.2 ms | 6.1-7.9 ms | 5.1-9.9 ms | 4.9-6.5 ms |
| 200 `SELECT ?` at once over a pool of 5, wall | 182-423 ms | 182-238 ms | 216 ms | 295 ms (1 run) |

Read it as: no difference that rises above the noise of the shared host. The
minimum latency of the sequential no-bind statement (3000 runs, 5 alternated
rounds, MySQL) was 685-841 us before and 759-1057 us after, which is the
price of the one extra loop iteration. The deterministic figure, in process
against a fake handle that answers from a zero timer (20000 statements, 2
rounds each): 51-52 us median per no-bind statement before and 61-62 us after
(about +10 us of CPU), 76-79 us before and 77 us after for a statement with
bind values (the extra iteration disappears behind its three loop turns).

Order of callbacks, identical before and after on both servers: five
`SLEEP`-staggered statements on five connections settle in the order the
server answered (1 2 3 4 5); statements pipelined on one pinned connection
settle in dispatch order (q1 ... q5, then the two with binds, then the
transaction); `t/27` pins the order offline and the depth (a callback runs at
`callback_depth` 0, not 1).

**What it costs, beyond the latency above.** Plain queries a `txn_do` coderef
issues back to back are no longer sent in one batch. They used to be taken by
EV::MariaDB while the `BEGIN`'s callback ran and sent together when it returned.
Now the first is sent at once, EV::MariaDB's `send_queue` holds the next ones
until it has read the first result (`pipeline_advance`, EV::MariaDB 0.08), and
each of them costs the round trip that the batch saved. The wire order is
unchanged. Measured above ("5 plain statements issued at once"): no difference
beyond the noise on this link; on a link with real latency the cost is one round
trip per statement beyond the first. `t/36-cancel-in-flight-mock.t` (sections 6
and 14) and `t/36-cancel-in-flight-live.t` (section 7) assert the new wire
sequence: the statement behind the first is on the wire after the first
answer, not with it. Section 7's premise (a statement cancelled while only
queued in EV::MariaDB) can no longer be made by a `then` right after an answer;
it is made behind a statement in flight.

**Tests.** Red before the change: `t/27-blocking-in-callback-mock.t`, rewritten
from asserting the refusal to asserting the return (12 of 39 fail on the k48
code: cases 1a to 1d and the depth), and `t/25-sync-fallback-live.t` (5 live
assertions). Replaced claims, said plainly: both files claimed *"refused, not
hung"*; they now claim *"returns"* -- that claim is replaced, not weakened, by
the k51 decision. `t/46-held-by-spawn-and-dry-loop-mock.t` section 3 (the held
statement) is removed with the registry it tested. The mock files that drive a
fake handle by hand (`t/12`, `t/21-deploy-async-mock`, `t/23`, `t/36-...-mock`,
`t/42`, `t/storage-facade-mock`) run the loop once without blocking
(`EV::run(EV::RUN_NOWAIT)`) after an answer before they look at a Future, which
is what the real loop does; their claims are unchanged. `t/51-async-parity-live.t`
(core's AsyncParity) passes on both servers.

No storage or component class changes its `@ISA`. The POD of
`DBIO::MySQL::EV::Future` (`await`), `DBIO::MySQL::EV::QueryExecutor`,
`DBIO::MySQL::EV::Storage::future_class`, `DBIO::MySQL::EV::Pool` and
`DBIO::MySQL::EV::TransactionContext`, the dist's `CLAUDE.md` and the
`dbio-mysql-ev` skill describe the new behaviour; the k48 addendum above is
history.

## Context

Core ADR 0014 (async storage interface) establishes the *other* direction of the
async/sync bridge: on plain synchronous storage every `*_async` call degrades to
an immediately-resolved Future (`eval` the sync op, wrap in
`future_class->done/fail`), so Future-shaped application code runs unchanged on a
non-event-loop storage. This ADR builds on that contract and does not restate it;
it records the *reverse* degrade, which core ADR 0014 explicitly leaves to the
real non-blocking driver dists.

`DBIO::MySQL::EV::Storage` is a genuinely non-blocking driver: its primitives
(`select_async`, `insert_async`, `txn_do_async`, …) are the real event-loop
operations and return a `Future` that resolves only when EV::MariaDB completes the
IO. But the rest of DBIO — `$rs->all`, `$row->update`, scripts, migrations — still
calls the *synchronous* storage methods `select`, `insert`, `update`, `delete`,
`txn_do`. On a sync-native storage those are the real implementation; here there
is no synchronous implementation to fall back to, only the async one.

## Decision

Implement every synchronous storage method as a one-line wrapper that calls its
async sibling and blocks on the resulting Future with `->get`
(`lib/DBIO/MySQL/Async/Storage.pm:477-505`): `select`, `select_single`, `insert`,
`update`, `delete`, `txn_do` are each `return $self->..._async(@_)->get`.
`future_class` is `'Future'` (`Storage.pm:60`), so `->get` is `Future.pm`'s
blocking get — it spins the EV event loop until the Future is ready, then returns
its value (or rethrows its failure). The async path is the single source of truth;
the sync path is a thin blocking adapter over it. The in-code section header names
this deliberately: "Sync Fallbacks … allow sync methods (->all, ->first etc.) to
work by blocking the event loop. Useful for scripts/migrations"
(`Storage.pm:473-475`).

The `TransactionContext` exposes the same sync wrappers
(`TransactionContext.pm:71-75`), so a `txn_do_async` callback that reaches for a
sync method gets the identical blocking behaviour against the pinned connection.

## Rationale

This is the mirror image of core ADR 0014's sync-degrade and it keeps the driver
on *one* implementation of each operation instead of two. A non-blocking driver
that also hand-wrote synchronous query code would have two code paths to keep in
agreement; routing sync through `async->get` guarantees they cannot diverge — the
sync method is, by construction, the async method run to completion. It also means
the MySQL-specific behaviours decided in the sibling ADRs (the LAST_INSERT_ID
round-trip, pinned-connection transactions, the SQLMaker choice) apply uniformly
to sync *and* async callers, because the sync call literally is the async call.

The cost — `->get` blocks the event loop while the query runs — is accepted on
purpose. Calling a sync method from inside a running event-loop application is a
category error the user has opted into; the methods exist for scripts and
migrations, where blocking is exactly what is wanted. This is shipped, hence
**accepted**, not proposed.

This driver is the structural twin of `dbio-postgresql-async`, which makes the
identical decision in its own ADR 0001. The decision is owned here for the MySQL
driver; the Pg ADR is referenced only to show the pattern is family-wide, not to
share policy.

## Consequences

- Sync and async results are identical by construction: `select` returns what
  `select_async(...)->get` returns; a failure in the Future is rethrown as a die
  from the sync call. There is no second implementation to drift.
- Calling a sync method (`->all`, `->update`, `txn_do`) from inside an active EV
  event loop blocks that loop until the query completes. This is acceptable for
  scripts/migrations and a footgun in a live event-loop app — by design, not an
  oversight.
- `future_class` is the real CPAN `Future` (`Storage.pm:60`), not core's
  `DBIO::Test::Future`; `->get` therefore drives a real EV loop. A driver that
  swapped `future_class` for a promise type whose `->get` did not block would
  break every sync method here, so the sync wrappers are coupled to
  `future_class->get` having blocking semantics.
