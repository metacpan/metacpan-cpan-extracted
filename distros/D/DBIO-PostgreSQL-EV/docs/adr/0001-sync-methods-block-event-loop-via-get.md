# ADR 0001 — Sync methods block the event loop via `->get`

- Status: accepted
- Date: 2026-06-21
- Tags: async, future, storage, sync-degrade, drivers
- Corrected: the *mechanism* the Decision states -- that `Future.pm`'s `->get`
  spins the event loop -- was wrong, and the sync methods died until karr k44
  (see the Amendment); the decision itself stands
- Amended: the first limitation the k44 amendment lists -- a refused `txn_do`
  coderef does not roll back cleanly -- is lifted by karr k48 (see the
  Amendment of that date)
- Amended: the second limitation the k44 amendment lists -- a blocking call
  in a callback that needs a second connection waits for good with a pool of
  one -- is lifted by karr k71: that wait is refused (see the Amendment of
  2026-10-07)
- Amended: the k71 amendment's first limitation -- the k44 refusal leaves the
  queued call queued, to run after the transaction -- is lifted by karr k85,
  and the loop running dry no longer leaves it queued either (karr k86); see
  the Amendment of 2026-10-08
- Amended: the second condition of the k71 refusal looked at the pool's
  connections only; a slot held by a spawn that is running counts as well
  (karr k88, see the Amendment of 2026-10-08 on a connection being opened)

## Amendment (2026-10-08, karr k88) — a connection that is being opened is held like one a callback holds

Condition 2 of the k71 amendment reads "no connection of that pool is idle,
and every one it holds is held by a callback that is running". It rested on a
sentence that stopped being true with core k277: *a caller is queued only when
the pool is at its size*. Core opens a connection synchronously, inside
`acquire`, and since k277 the spawn holds its slot from before the first code
it calls that is not the pool's -- the conninfo provider (an AccessBroker's
answer), `_transform_conninfo`, `_create_connection`. A call that comes in from
inside is queued behind the spawn while the pool counts fewer connections than
its size; in a pool of one, none. This transport adds a second stretch of the
same spawn: the replay of `on_connect_do` / `on_connect_call`
(`_run_pool_connect_statement`) runs the EV loop until the server has answered,
with the connection counted, not idle, and held by no callback.

In both the spawn is a frame on the call stack, and whatever makes a blocking
call meanwhile -- the broker itself, or a callback the loop runs while the
broker's client fetches or the replay waits -- runs above it. The connection is
handed out only after the spawn has returned, so the wait cannot end. Condition
2 did not see it: it found no connection, or one no callback holds, and let the
wait run. Measured offline and against PostgreSQL 18.6 with EV::Pg 0.07: with
nothing else on the loop the wait died with "... the EV loop has nothing left
that could complete it" (true, and no hint at the cause); with a watcher that
keeps the loop alive -- the storage's own LISTEN connection is one -- it hung,
the caller queued, nothing sent. With a second connection held by a callback
(pool of two) it was refused already, by a text that said callbacks held every
connection.

**What changed.** Condition 2 is now: *no connection is idle, and every slot
the pool has taken is held by something on the call stack* -- a callback that
is running (as before), or a spawn that is. `Pool::_pg_opening` counts the
slots a running spawn holds: the entries of core's `_spawning`, and the
connections `_run_pool_connect_statement` has marked for the time it runs
(`Future->_replaying`). Both are synchronous, so a spawn that is counted is
below whoever asks; that is what makes it certain. The refusal names the size
of the pool and how many of its connections the pool is opening in a call this
one runs inside; where no spawn is involved the k71 text stands unchanged. The
refused call leaves the queue and does not run, as before. A broker that makes
the blocking call itself and lets the refusal through fails the call whose
connection was being opened, and the spawn took no slot.

**What it does not change.** A spawn in flight alone refuses nothing: with
another connection busy with a statement in flight the call waits for that one
and runs on it, and a call that finds room -- a pool of two with nothing open
-- is not queued at all and opens a connection of its own, the broker asked a
second time from inside its own answer. A queued call nobody blocks on stays
queued and runs once the spawn has returned. Not seen: whatever else runs the
loop inside a spawn, not through the connect statement seam.

Reading `_spawning` is reading a private slot of core's pool, as
`_connections` was read before; core has no accessor for either.

Pinned offline by `t/77-blocking-behind-spawn-mock.t` and against PostgreSQL by
`t/78-blocking-behind-spawn-live.t`.

## Amendment (2026-10-08, karr k85, k86) — every wait given up on takes the queued caller out of the queue

The k71 amendment refused a blocking call queued for a connection its own
callbacks hold, and took the caller out of the pool's queue. Two other ways
`await` gives a wait up still left it queued, and the rule behind the k71 text
-- *a call that has no connection yet does not run after its caller was told
the wait failed* -- holds for them as much:

- **The k44 refusal** (a result is due on the connection whose callback runs).
  It said, deliberately, "cancels nothing, the refused operation still
  completes", and retained the chain. That is true of a statement on the wire.
  A blocking call on the storage in a `txn_do` coderef with a `$ctx` statement
  in flight is not on the wire: it is queued for the transaction's own
  connection, and the retained chain kept it there. After the transaction's
  `ROLLBACK` (or `COMMIT`) `release` handed it the connection and it ran --
  `BEGIN in-txn ROLLBACK inner` on the wire, a refused `insert` written outside
  the transaction (karr k85, measured against PostgreSQL as well).
- **The loop running dry** ("... nothing left that could complete it"). `await`
  died and the caller dropped the chain, but the waiter stayed pending in the
  queue; the next `release` handed it the connection, a sequence Future was
  lost and the connection never came back (available 0, size 1; karr k86).

**What changed.** One path, `Future::_withdraw_queued`, is taken by all three
ways out (the k71 refusal included): the caller is taken out of the queue
(`_withdraw_waiter`) and *failed* with the text the caller sees, before
`await` raises. A refusal for a result due still retains the chain, which now
holds only what is on the wire: the statement of the `$ctx` completes, the
queued call does not run. A convergent of a queued call and a statement on
the wire fails with the queued call, as `Future.pm` has a convergent do. A
callback that dies as the waiter is failed is warned about; the pool is
already in order. Which message the caller gets is the branch's own.

**What it does not change.** The mark's reach (the Future must be chained off
the queued caller through `new`); the k71 limitations that stay. In
particular a `txn_do` coderef that *returns* the Future of a queued storage
call (karr k87) is still not seen: core chains the returned Future itself and
the Future a blocking caller waits on carries no mark. Fixing that needs a seam
in core (a hook that is handed the Future the coderef returned).

Pinned offline by `t/56-blocking-on-empty-pool-mock.t` (sections 5a-5e) and
against PostgreSQL by `t/62-blocking-on-empty-pool-live.t` (sections 6, 7); the
k87 state is held by `t/70-txn-coderef-queued-call-mock.t`.

## Amendment (2026-10-07, karr k71) — a blocking wait for a pooled connection that cannot come back is refused too

The second item of the k44 amendment's "What the refusal does not cover" no
longer holds. It recorded that a blocking call inside a `then` on a pooled
Future needs a second connection and, with a pool of one, waits for good. The
same holds for a blocking call on the *storage* in a `txn_do` coderef
(`$storage->select` where `$ctx->select_async` was meant), and with a pool of N
for a call nested in N such callbacks: `acquire` queues the caller for a
connection its own call chain holds. Nothing is sent, so the k44 refusal --
more than the delivering statement pending -- does not see it, and the
no-watcher guard of `await` does not fire: EV::Pg keeps the read watcher of
the held connection counted while the callback it delivers to runs. Measured
against PostgreSQL for karr k73 (`t/62-blocking-on-empty-pool-live.t` before
this amendment): still blocked after a second, the caller queued,
`pending_count` 1, the server listing the backend as `idle` (`idle in
transaction` after `BEGIN`). No error, no timeout, no CPU.

**Such a wait is refused**, the way dbio-mysql-ev refuses its twin (its karr
k53), with *"Blocking wait refused: …"*, naming the size of the pool and what
to do instead: the `*_async` methods chained with `->then`, in a `txn_do`
coderef the context's, or a larger `pool_size`. `await` refuses when two
things hold, checked on entry and before every loop iteration:

1. *The Future it waits for is chained off a queued caller.*
   `DBIO::PostgreSQL::EV::Pool::_new_waiter` -- core's waiter seam (core k256)
   -- marks the Future a queued caller waits on with its pool, and
   `DBIO::PostgreSQL::EV::Future::new`, called on an instance, carries the mark
   to the new Future: that is how `Future.pm` makes the Future of every `then`
   and the one a convergent returns. The mark is `Future`'s user data (`udata`,
   Future 0.49, this dist's minimum), and holds caller and pool weakly.
2. *No connection of that pool is idle, and every one it holds is held by a
   callback that is running*: it has a delivery frame of the k44 mechanism on
   the call stack, and EV::Pg counts nothing but the delivering callback on it
   (`pending_count <= 1`).

2 is sound because of what the two holders do. A pooled statement's callback
settles its Future and releases the connection after, so the release waits for
the `then` callbacks to return. A transaction gives its connection back after
`COMMIT` or `ROLLBACK` was answered, and an answer on a connection whose
callback is still running cannot be delivered -- that is the k44 refusal, which
is checked first. Each half alone refuses waits that would have ended, and
`t/56-blocking-on-empty-pool-mock.t` has a case that fails for each: a pool
that is merely exhausted behind a statement in flight (top level and in a
callback), a connection still connecting, a transaction that holds a
connection while none of its callbacks runs, and a blocking wait for something
else while a call nobody waits for is queued for the held connection.

**Where this differs from dbio-mysql-ev.** There a pooled statement's
connection is released before its caller's `then` callbacks run (the release
is the first `on_ready` of the dispatch), so only a transaction holds a
connection across a callback. Here the pooled path settles first and releases
after (karr k44, k51), so a `then` on any pooled statement holds its
connection: the plain case -- `$storage->select` in a `then` with
`pool_size => 1` -- is refused, not only the transaction case. No count of
statements in flight is kept per connection: EV::Pg's `pending_count` is that
count, and a connection whose callback runs with a statement in flight is the
k44 refusal's. And the check is not repeated when the loop has run dry: there
the answer to the last statement in flight is what makes the wait hopeless and
can leave the loop dry; here the held connection's watcher keeps the loop
alive for as long as its callback runs.

**The refused call does not run.** A queued caller has no connection yet.
`await` takes it out of the pool's queue
(`DBIO::Storage::PoolBase::_withdraw_waiter`) and *fails* it; the failure
reaches the waiting Future through its chain, and `get` dies with it. Nothing
is cancelled and nothing is retained. A refusal that only died and left the
caller queued would have the next `release` hand it the connection: the refused
call would run after its caller was told it had failed, or -- its chain dropped
-- the connection would be lost and the pool of one wedged (reproduced by
mutation in `t/56`). A call queued for the same connection that nobody blocks
on is not touched and runs once the callback has returned.

What it does not cover:

- (Where the k44 refusal applies as well, k44 speaks first. This used to leave
  the queued call queued, to run after the transaction; see the amendment
  of karr k85, k86 above.)
- A blocking wait on a Future that reaches a queued caller without being
  chained off it -- a `then` callback that *returned* the Future of a storage
  call, on a Future that was pending before, or a convergent whose first
  component is not the queued one. It waits as before.
- A connection held with none of its callbacks running counts as one that can
  come back. A blocking call queued behind a transaction that waits for
  something that never happens waits as long as that does.
- A transaction whose coderef returns a Future that depends on a call queued
  for the transaction's own connection
  (`txn_do(sub { $storage->select_async(...) })`, pool of one). The transaction
  waits for the call and the call for the connection; at top level `get` dies
  with *"… the EV loop has nothing left that could complete it"* and the
  transaction stays open. Ending that needs a bound on `acquire`.
- The callbacks that are not marked, as for k44: the LISTEN connection's
  notifications, the pool's connect-action replay.

No core change; no `@ISA` change. Pinned offline by
`t/56-blocking-on-empty-pool-mock.t` and against PostgreSQL by
`t/62-blocking-on-empty-pool-live.t`.

## Amendment (2026-09-27, karr k48) — a refused `txn_do` coderef rolls back cleanly

The first item of the k44 amendment's "What the refusal does not cover" no
longer holds. It recorded that a `txn_do` coderef that dies while its statement
is still running on the pinned connection -- because a blocking `$ctx` method
was refused, or after `$ctx->insert_async(...); die` -- does not roll back:
libpq refuses core's `ROLLBACK` ("another command is already in progress"),
`txn_do` fails with that error, and the connection goes back to the pool with
the transaction open. Measured again on PostgreSQL 18.6 with EV::Pg 0.07 before
the fix (`t/44-txn-inflight-live.t` against the previous `Storage.pm`): the
next call on the pool's one connection ran inside the open transaction and saw
the uncommitted row, and an `ALTER TABLE` from another session ran into its
`lock_timeout`.

**What changed.** `_query_async_pinned` runs one statement at a time per
connection outside pipeline mode: a statement issued while one of its
statements is in flight on that connection waits in a queue and is sent from
the completion callback of the one before it -- before that callback settles
its Future, so the `BEGIN` callback's coderef, and every `then` callback, finds
the statement it issued already in flight. That order is what keeps the
refusal of this ADR loud: the refused wait finds more than one result due and
dies, instead of waiting for a statement that would only be sent after it.
Core's `ROLLBACK` (and `COMMIT`) goes through the same seam and so waits for
the statement in flight; the transaction fails with the coderef's own error --
the refusal, or its die -- and the connection comes back IDLE and stays in the
pool: the rollback leaves it clean, so it is not retired.
A statement issued on the connection after the transaction's `COMMIT` or
`ROLLBACK` was issued is refused rather than queued behind it, where it would
run outside the transaction. Pipeline mode is untouched -- noted by
`_pipeline_enter` / `_pipeline_exit`, the statements are sent at once -- and a
statement EV::Pg refuses at dispatch fails its Future with EV::Pg's error
instead of escaping `_query_async_pinned`. No core change; no `@ISA` change.

The refusal itself is unchanged, and the other two items stand: a blocking call
inside a `then` on a pooled Future still needs a second connection, and the
LISTEN connection's notifications and the pool's connect-action replay are
still not marked. The replay runs its own nested loop
(`_run_pool_connect_statement`); since a queued pinned statement is now in
flight while the previous one's callbacks run, a pool spawn with connect
actions from such a callback is one more place where a nested loop can read a
result due on the delivering connection. Not measured; noted on karr k48.

Pinned by `t/43-txn-inflight-mock.t` (offline, a stand-in EV::Pg that refuses a
second statement in flight as libpq does) and `t/44-txn-inflight-live.t`.

## Amendment (2026-09-27, karr k44) — `->get` never waited; a Future that runs the EV loop does, and refuses a wait EV::Pg would turn into a spin

The decision stands: every sync method is its async sibling run to completion,
`return $self->X_async(@_)->get`, one implementation, no second code path. What
was wrong is the claim that made it work. `future_class` was `'Future'`, and
`Future.pm`'s `get` knows no event loop: on a pending Future it calls `await`,
which `Future` leaves to subclasses and by default dies with *"Future=HASH(0x…)
is not yet complete and does not provide ->await"* (Future 0.52). Every Future
of this transport is settled from the EV loop, by an EV::Pg callback, so it is
always still pending when a sync method calls `->get`.

Measured on PostgreSQL 18.6 (EV 4.37, EV::Pg 0.07, Future 0.52), reached as
`$schema->storage->async` on a `dbi:Pg:` + `{ async => 'ev' }` schema: `insert`,
`select`, `select_single`, `update`, `delete` and `txn_do` (commit and rollback)
all died with that message. The die was not clean: a died `insert` never ran,
the dropped chains held their pooled connections ("lost a sequence Future";
after seven dies a pool of three had none available) and the next driven wait
timed out. No test had driven the sync path over this transport. The ORM
(`$rs->all`, `$row->update`, `$schema->txn_do`) was never affected: since core
ADR 0030 an `{ async => 'ev' }` schema keeps its sync DBI storage and the ORM
goes through that; these methods are reached by code holding the backend.

**What makes it block now.** `future_class` returns
`DBIO::PostgreSQL::EV::Future`, a `Future` subclass whose `await` runs
`EV::run(EV::RUN_ONCE)` until the Future is ready -- the pattern of
`IO::Async::Future` and the `Future::IO` implementations, as in dbio-mysql-ev
(karr k48 there). A new standalone class; no storage or component class changes
its `@ISA`. It reaches every Future a sync method waits on: `pool` passes it to
`DBIO::Storage::PoolBase->new` (acquire, waiter and readiness Futures -- on a
cold pool the first link of every chain), every Future the storage settles from
an EV::Pg callback is built from it, and core's orchestration builds Futures
only from `future_class` or by chaining on the transport's, whose combinators
keep the class. No core change. `await` croaks rather than spins when an
iteration leaves no watcher that keeps the loop alive while the Future is still
pending.

**Where a nested wait breaks: EV::Pg delivers to the head of its queue.** libev
runs loops recursively, so a sync call from inside an EV callback works (a
timer's, measured). But EV::Pg keeps the callback it is delivering to at the
head of the connection's callback queue until that callback returns (`Pg.xs`
`process_results`: `deliver_result`, then `advance_cb_queue`; the 0.02 source
has the same shape). A nested loop that reads the next result on that
connection hands it to the still-running callback a second time, shifts every
later result onto the wrong callback, and then loops in C forever -- `cb_head`
set, `PQisBusy` false -- at 100% CPU, where no EV timer and no `alarm` fires.
Measured on raw EV::Pg 0.07:

- a query issued on connection X from inside X's callback, then waited for
  (`query_params` and plain `query` alike -- unlike EV::MariaDB, EV::Pg sends
  at once and queues nothing): the outer callback got the inner result, the
  inner callback never fired, then 20 s of user CPU until `timeout` killed it;
- the same wait on another connection: fine;
- in pipeline mode, a wait inside the first result's callback: fine when the
  rest of the batch arrived in the same read (PostgreSQL flushes pipeline
  output at the Sync, so small batches do), and the same mis-delivery and spin
  when the next result arrived during the wait (a large, slow second
  statement).

Only this transport's connection-bound callbacks can hit it: a `then` on its
Futures, a `txn_do` / `txn_do_async` coderef (it runs inside the `BEGIN`'s
callback on the pinned connection), a pipeline batch.

**Such a wait is refused, loudly** (option (b) of dbio-mysql-ev k48, adapted).
Every callback the storage hands to EV::Pg to settle one of its Futures
(`_dispatch_query`, `_query_async_pinned`, `_pipeline_sync`,
`_dispatch_notify`, `copy_in`) marks its connection as *delivering* for as long
as it runs -- a scope guard taken first thing in the callback, restored on
return and on die, nesting correctly; set inside the callback rather than by
wrapping it, so the callback EV::Pg keeps is still the one created in the
dispatch sub (karr k29 / k30). EV::Pg counts the delivering callback in
`pending_count` until it returns, so a delivering connection with
`pending_count > 1` has a result due that a nested loop would mis-deliver.
`await` dies then -- on entry and before every iteration -- with *"Blocking
wait refused: …"*, pointing to the `*_async` methods, after retaining the
awaited Future so the chain the dying caller drops still completes. The refusal
is deterministic where the failure is timing-dependent (the pipeline case), and
it cancels nothing.

What the refusal does not cover:

- A refused `txn_do` coderef does not roll back cleanly. Its statement is still
  running on the pinned connection when core sends `ROLLBACK`, which libpq
  refuses ("another command is already in progress"); `txn_do` fails with that
  error and the connection goes back to the pool before the transaction has
  ended. This predates the refusal -- at HEAD before k44 a coderef that dies
  while one of its `*_async` statements runs, or calls a blocking `$ctx`
  method (then dying with the `->await` croak), ends exactly the same way --
  and is tracked separately (karr k44 notes). The refusal replaces the spin,
  nothing more.
- A blocking call inside a `then` on a pooled Future needs a second connection
  -- the one whose callback runs is still checked out -- and with a pool of one
  it waits for good (measured; no spin, an EV timer still fires).
- The dedicated LISTEN connection and the pool's connect-action replay
  (`_run_pool_connect_statement`, which runs its own nested loop) are not
  marked.

Pinned offline by `t/31-ev-future-mock.t` (a fake EV::Pg that completes on EV
timers and keeps the delivering callback counted as the real one does;
mutations of the class, the wiring, the refusal and `retain` each fail it) and
live by `t/30-sync-fallback-live.t` (each sync method returns what its `*_async`
sibling resolves with, a failure is a die with the server error, no connection
stays checked out; sync calls from a timer callback and inside a pooled `then`;
the pipeline refusal).

**Corrections to the text below.**

- *Decision*: the sync methods are core's `DBIO::Storage::Async` `select` …
  `deploy`, inherited unchanged since the thin-transport refactor
  (`t/06-thin-transport-structure.t` pins it); `Storage.pm:649-677`,
  `Storage.pm:64` and `Storage.pm:645-647` predate it. `future_class` is
  `DBIO::PostgreSQL::EV::Storage::future_class`. The context's blocking methods
  are core's `DBIO::Storage::Async::TransactionContext` (ADR 0002 amendment,
  karr k32), not `TransactionContext.pm:68-72`.
- *Consequences*, last bullet: "`future_class` is the real CPAN `Future` …
  `->get` therefore drives a real event loop" is the error this amendment
  corrects. The coupling it names is right, and is now what
  `DBIO::PostgreSQL::EV::Future` exists for.

## Context

Core ADR 0014 (async storage interface) establishes the *other* direction of
the async/sync bridge: on plain synchronous storage, every `*_async` call
degrades to an immediately-resolved Future (`eval` the sync op, wrap in
`future_class->done/fail`). That makes Future-shaped application code run
unchanged on a non-event-loop storage. This ADR builds on that contract and does
not restate it; it records the *reverse* degrade, which is a driver concern core
explicitly leaves to the real non-blocking dists.

`DBIO::PostgreSQL::EV::Storage` is a genuinely non-blocking driver: its
primitives (`select_async`, `insert_async`, `txn_do_async`, …) are the real
event-loop operations and return a `Future` that resolves only when EV::Pg
completes the IO. But the rest of DBIO — `$rs->all`, `$row->update`, scripts,
migrations, `Deploy` — still calls the *synchronous* storage methods `select`,
`insert`, `update`, `delete`, `txn_do`. On a sync-native storage those are the
real implementation; here there is no synchronous implementation to fall back to,
only the async one.

## Decision

Implement every synchronous storage method as a one-line wrapper that calls its
async sibling and blocks on the resulting Future with `->get`
(`lib/DBIO/PostgreSQL/EV/Storage.pm:649-677`): `select`, `select_single`,
`insert`, `update`, `delete`, `txn_do` each are `return $self->..._async(@_)->get`.
`future_class` is `'Future'` (`Storage.pm:64`), so `->get` is `Future.pm`'s
blocking get — it spins the event loop until the Future is ready, then returns its
value (or rethrows its failure). The async path is the single source of truth;
the sync path is a thin blocking adapter over it. The in-code section header names
this deliberately: "Sync Fallbacks … allow sync methods (->all, ->first etc.) to
work by blocking the event loop. Useful for scripts/migrations"
(`Storage.pm:645-647`).

The `TransactionContext` exposes the same sync wrappers
(`TransactionContext.pm:68-72`), so a `txn_do_async` callback that reaches for a
sync method gets the identical blocking behaviour.

## Rationale

This is the mirror image of core ADR 0014's sync-degrade and it keeps the driver
on *one* implementation of each operation instead of two. A non-blocking driver
that also hand-wrote synchronous query code would have two code paths to keep in
agreement; routing sync through `async->get` guarantees they cannot diverge —
the sync method is, by construction, the async method run to completion. It also
means the PostgreSQL-specific behaviours decided in the sibling ADRs (RETURNING,
pinned-connection transactions, the PostgreSQL SQLMaker) apply uniformly to sync
*and* async callers, because the sync call literally is the async call.

The cost — `->get` blocks the event loop while the query runs — is accepted
on purpose. Calling a sync method from inside a running event-loop application is
a category error the user has opted into; the methods exist for scripts,
migrations and `Deploy`, where blocking is exactly what is wanted. This is shipped
and test-pinned, hence **accepted**, not proposed.

## Consequences

- Sync and async results are identical by construction: `select` returns what
  `select_async(...)->get` returns, a failure in the Future is rethrown as a die
  from the sync call. There is no second implementation to drift.
- Calling a sync method (`->all`, `->update`, `txn_do`) from inside an active
  event loop blocks that loop until the query completes. This is acceptable for
  scripts/migrations and a footgun in a live event-loop app — by design, not an
  oversight.
- `future_class` is the real CPAN `Future` (`Storage.pm:64`), not core's
  `DBIO::Test::Future`; `->get` therefore drives a real event loop. A driver
  that swapped `future_class` for a promise type whose `->get` did not block
  would break every sync method here, so the sync wrappers are coupled to
  `future_class->get` having blocking semantics.
