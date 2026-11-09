# ADR 0007 — The transport holds its statements in flight: the caller gets a Future of its own, and a closed connection ends the flight

- Status: accepted
- Date: 2026-10-08
- Tags: async, pool, lifecycle, future-io, teardown, builds-on-core-0047
- Origin: karr k46 and k39 — two findings, one cause.

## Context

A statement on the wire of this transport is a chain of Futures: a
`Future::IO` poll on the dup of the connection's socket (`_await_readable`),
the collect chained onto it with `->then` (`_await_query_result`), and, for a
pooled query, the release hung off the result. Future.pm holds a Future derived
with `->then` only **weakly**. So that chain belonged to whoever held its end,
and its end was what `_query_async` returned: with a connection at hand,
`acquire->then(...)` returns the statement's Future itself. Nobody else knew
it. Two findings came from that.

- **A Future the caller let go of took the statement with it (karr k46).**
  Fire-and-forget — `create_async` in void context, a notify nobody waits for
  — dropped the chain. The poll then resolved into nothing (Future.pm: *lost a
  sequence Future*), `_collect_result` never ran, the release never ran: the
  connection stayed checked out, and a pool of one served nobody again.
  Confirmed live against PostgreSQL, on the built-in `Future::IO`
  implementation and on IO::Async. A caller that let go while still *queued*
  for the pool lost the connection one step earlier: the release handed it to
  a waiter with nothing behind it.
- **A teardown could not name what was in flight (karr k39).** `disconnect`
  and the pool's `shutdown` are core's; core's pool closes the checked-out
  connection and knows no Future to fail. The statement's Future stayed
  pending, the loop went on watching the dup of a closed connection's socket,
  a late answer ran `_collect_result` on that connection, and the completion
  callbacks — `_release_on_ready`, `_mark_if_fatal`, `_report_abandoned`,
  `_queue_conn_reported_dead` — asked `$storage->pool`, which builds lazily:
  a new, empty pool on a storage just disconnected.

Core met the same structure one stage earlier and decided it (core ADR 0047,
addenda 2026-09-28, karr core k255 / k256 / k258): the caller of `acquire`
gets a Future of its own, never a `->then` off the chain; the pool holds the
chain until it settles; `shutdown` fails the caller the connection loop cannot
reach and lets go of the chain; a forked child drops what it inherited
unsettled; nothing is settled in global destruction (karr core k254). Core's
`txn_do_async` retains its own sequence for the same reason. The stage this
transport owns, the statement in flight, had none of it. The pinned statement
queue (karr k33) had half: it kept the flight on the connection and gave the
caller a proxy; the pooled path had nothing, and the storage knew no flight
either way.

It has to be decided here. The flights are this transport's Futures; core's
pool cannot know them.

## Decision

1. **The storage holds every flight.** A statement put on the wire by
   `_query_async` or `_query_async_pinned` — queued or, on a connection that
   is no hashref, unqueued — is entered into a register on the storage
   (`_flight_register` in `lib/DBIO/Async/Storage.pm`) with its Future, its
   connection and the pool it was dispatched with, and leaves it as the first
   thing that happens when its Future settles. A statement that never took
   off — its dispatch died, or the queue refused it — is not entered.

2. **The caller gets a Future of its own**, of the flight's class (so `->get`
   on it runs the flight's loop), settled from the flight's outcome. A pooled
   connection goes back to the pool before the caller's Future is settled, so
   the order a caller sees is unchanged. The caller's cancel is passed on to
   the flight; a flight cancelled on the wire retires its connection as before
   (karr k29, k33). A pooled query's wait for the pool, before there is a
   flight, is held with `->retain`, as core's `txn_do_async` holds its
   sequence.

3. **A Future let go of is carried through.** Collected, classified by
   `_conn_error_is_fatal` if it failed, its connection handed back once or
   retired. Nothing is invented to announce a failure nobody waits for.

4. **A connection the pool closes ends the flight on it.**
   `DBIO::Async::Pool::_shutdown_connection` — this dist's override of the
   seam through which core's pool closes every connection, at `shutdown` and
   at a retirement — calls `_abandon_flights_on($conn)` on the storage before
   the driver's `_shutdown_pool_connection`. For each flight on that
   connection, in dispatch order: the caller's Future fails, saying the
   connection was closed under the statement and that whether it took effect
   is unknown; then the flight is let go of, which drops the poll. A pinned
   statement queue on the connection refuses from then on, with a reason of
   its own — the rule for a statement cancelled in flight: what waits fails
   unsent, in issue order. A callback that dies there is reported to the
   pool's `on_error` and stops nothing.

5. **A connection the pool closed gets nothing more sent — with or without a
   statement in flight.** `_abandon_flights_on` marks every hashref
   connection it is called for: the connection gets a pinned statement queue
   that only refuses, or the one it has is set to. Whatever is issued on it
   afterwards — the next statement of a transaction that was between two
   statements at the teardown, core's `ROLLBACK` for it — fails saying the
   connection was closed and is not handed to `_submit_query`. A connection
   that is no hashref has no place for the mark; there the driver's handle
   refuses. A connection that goes back to the pool open never carries it:
   the seam is called for closes only, and the queue of a live connection is
   removed when it falls idle.

6. **Nothing is ended where core closes nothing.** The teardown needs no
   fork logic of its own: a forked child that tears down what it inherited
   has its connections dropped unclosed by core's `_verify_pid`, so the seam
   is not called and nothing of the parent's is settled. In global destruction
   `_abandon_flights_on` returns at once. A storage that is merely dropped
   with a statement in flight is not torn down under it: the flight holds the
   storage, completes, and the storage is freed after it.

7. **A flight inherited across a fork does nothing in the child.** A `fork`
   copies the loop's watch list, and the socket is as readable in the child
   as in the parent: a child whose own loop turns resolves the parent's poll.
   `_await_readable` therefore continues every poll through
   `_in_this_process_cb`: in the process that made the poll, its result; in
   any other, a Future that never settles. So nothing chained onto the poll
   runs in the child — no `_collect_result`, no release, no report to the
   pool, no settled Future, no callback of the parent's — for the first poll
   of a statement, for the re-poll a driver makes from `_collect_result`, and
   for a connection still coming up. The inherited entries stay in the child's
   copy of the register, inert.

8. **No completion builds a pool.** What a settled statement tells a pool —
   dead, abandoned, coming back — it tells the pool it was dispatched with:
   for a pooled query the pool `acquire` was called on, for a pinned statement
   the pool the storage had at dispatch (`_built_pool`), which may be none.
   No pool means nobody to tell, and is no error.

9. **One place gives a poll up.** `_let_go` is the only sub in this dist that
   cancels a Future — a flight on the caller's cancel or at a close, the
   listen watch loop's pending Future on `_listen_unwatch` — as
   `_await_readable` is the only one that makes a poll.

## Rationale

- **The close seam, not an override of `shutdown` or `disconnect`.** Every
  close goes through `_shutdown_connection`, one connection at a time, and
  nothing else does. Ending the flight there needs no second walk over the
  pool's connections and no copy of core's rules about which process may
  close what: where core closes, the flight ends; where core drops (a forked
  child), it does not. It also covers a close no shutdown is part of — core's
  hand-back of a transaction connection a pipeline left unusable sends a
  `ROLLBACK` it does not wait for and retires the connection under it. The
  cost is the error text: the seam cannot tell a disconnect from a pool
  shutdown from a retirement, so the message names all three.
- **Fail, not cancel.** Cancelling the flight is the only way to reach the
  poll, and a cancelled Future tells its holder nothing. Hence the caller's
  own Future, failed first with what happened; the cancel of the flight then
  finds it settled.
- **The pool travels with the flight.** The first attempt at k39 read the
  pool off the storage at completion instead of asking `pool()`. With no pool
  there, `_mark_if_fatal` took "no pool" for a failed report and warned —
  three hard *nothing warned* assertions broke. The completion does not know
  which pool the connection came from unless the dispatch tells it; and with
  none, there is nothing to report to rather than something that failed.
- **`_abandon_flights_on` never dies.** It runs inside core's `eval` around
  `_shutdown_connection`; a die would silently skip the close.
- **The transport refuses a closed connection, not the driver.** A DBD
  refuses a handle it disconnected, and the first version of this ADR left an
  idle connection to that. Not every client library does: one that takes the
  statement leaves a poll on the dup of a dead socket, which never fires, and
  a Future that never settles — the pending-for-good outcome this ADR exists
  to end. The reason text names no statement in flight, so it is true for an
  idle connection too.
- **The pid guard sits at the poll, not at the flight.** A guard in the
  collect callback of `_await_query_result` would cover a statement's first
  poll only; a driver waiting for the rest of a result polls again through a
  closure of its own, which the base cannot reach. Every one of those polls
  is made by `_await_readable`, so that is where the guard is — as the listen
  watch loop guards its own steps with the pid it recorded (ADR 0005).
- **Never settling, not dropping.** Core drops what a child inherited; a
  dropped flight would leave the poll with a continuation that is gone, and
  Future.pm warns *lost a sequence Future* when the child's loop then fires
  it (core's own open point, karr core k261). Kept and inert, it is silent.

## Consequences

- `_query_async` no longer returns the statement's Future. Code that kept it
  sees the same outcomes in the same order; code that let go of it now has its
  statement finished instead of its pool wedged.
- A statement in flight at `disconnect` or at the pool's `shutdown` now
  **fails there**. Before, it stayed pending until the socket stirred — with a
  server that never answered, for good. Whether the statement took effect on
  the server is not known and the error says so; the base neither drains nor
  cancels it there (as for a cancel, karr k29).
- `DBIO::Async::Pool` still overrides none of `shutdown`, `release`,
  `acquire`; `DBIO::Async::Storage` still inherits core's `disconnect`. A
  driver that brings its own `DBIO::Storage::PoolBase` subclass calls
  `_abandon_flights_on` from its `_shutdown_connection`, or keeps the old
  behaviour.
- `_abandon_on_cancel`, `_mark_dead_on_fail` and `_release_on_ready` take the
  pool (and the last one the caller's Future) as further arguments. They are
  private; no driver in the family calls or overrides them.
- A connection closed while **no** statement is on it has nothing to fail at
  the close. A transaction between two statements learns of the teardown from
  its next one — refused by its context after a `disconnect`, by the transport
  after a bare pool shutdown — and its `ROLLBACK` is refused unsent either
  way.
- `_await_readable` returns a Future chained off the poll, no longer the poll
  itself. A driver that calls it — to wait for the rest of a result — chains
  on it as before.
- A forked child must not expect a statement it inherited in flight to
  complete there: it never does. The parent's does.
- On a `Future::IO` implementation that does nothing when a poll is cancelled
  (Future::IO::Impl::IOAsync 0.805), the loop keeps its watch on the dup until
  the socket next turns readable. The transport's part holds regardless: the
  caller has failed, and the late answer is not read (`t/32`).
- Pinned by `t/31-dropped-query-future.t` (k46), `t/30-disconnect-statement-in-flight.t`
  (k39; also transactions, the queue, an idle connection closed, repetition,
  a dying callback, a retirement, a forked child that tears down and one
  whose loop turns, global destruction), `t/32-flights-on-io-async.t`
  (both on IO::Async) and the one-way-in / one-way-out check in
  `t/13-seam-ownership.t`.

## Future architecture work (tracked cross-repo, not here)

- **core, done**: `DBIO::Storage::Async::_txn_hand_back` handed the
  transaction's connection back through `$self->pool`, which built a new
  pool on the disconnected storage when a transaction that was between two
  statements at a `disconnect` went on and failed. Fixed in core by dbio
  4aa01dc67 (karr k46 of this board): the connection goes back
  to the pool it was acquired from. `t/30` asserts it, no longer as a
  `TODO`.
- **here, karr k37 / k38**: what the `Future::IO` implementations do with a
  cancelled poll. `_let_go` is the place a decision about that would go.
- **here, karr k47**: what is still sent on a pinned connection the driver
  reported dead. Untouched by this ADR.

## Addendum 2026-10-08 -- a connection retired while it comes up ends its readiness wait too (karr k49)

The decision stands. The rule "a flight ends where the pool closes its
connection" covers the other poll this transport makes: the readiness poll of a
connection still coming up (`_await_conn_ready`). Core ADR 0047 k261 retires
such a connection and parks the pool's chain on the readiness Future instead of
cancelling it; a poll left behind kept the dup of the closed socket and the
connection on the loop, and asked the closed connection whether it was ready.

- The wait is kept on the connection hashref under `_dbio_async_ready` (its
  Future and its current poll, both weak, removed as the Future settles). A
  connection that is no hashref keeps none, as with the statement queue.
- `_abandon_flights_on` lets go of that poll (`_let_go`, still the one place a
  poll is given up; `_await_readable` the one that makes it). That settles
  nothing above the poll, so the wait is ended in a second step:
  `DBIO::Async::Pool::_retire_connection` fails the readiness Future after
  core's own retirement has parked its hand-over. The caller then hears core's
  reason, and the failed chain offers the slot to the next caller (core k260).
  During `shutdown` nothing is failed here: core fails its callers and cancels
  the chain itself.
- `_retire_connection` is therefore no longer inherited unchanged; `t/13` and
  `t/23` count it as a pool override. It adds a step after core's and replaces
  none of it.
- Pinned by `t/27`, section 4.
