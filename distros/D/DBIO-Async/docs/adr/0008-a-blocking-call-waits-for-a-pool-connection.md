# ADR 0008 — A blocking call waits for a pool connection: the pool's waiter drives Future::IO, and a wait that dies takes itself back

- Status: accepted
- Date: 2026-10-09
- Tags: async, pool, sync-wrappers, future-io, refines-0001, builds-on-core-0047
- Origin: karr k30. Maintainer decision 2026-10-09: wait, rather than refuse.
  Refines ADR 0001.

## Context

ADR 0001: a sync storage method is its async sibling run to completion with
`->get`. With the pool exhausted, core's `PoolBase::acquire` queues the caller
on a waiter, and the sync call croaked instead of waiting:

    Future=HASH(...) is not yet complete and does not provide ->await

Reproduced with a pool of one, an async query holding the connection, and a sync
`select`. The cause is Future.pm's: every `->then` off a *pending* Future is
made with that Future's own `new`, so the whole chain up to core's `->get` — the
Future `acquire` returns, the query chained off it, the Future finally
`->get`ted — is of the class of the waiter. The waiter was `future_class->new`,
a plain `Future`, which knows no event loop and cannot `await`. A pool that
hands its connection out at once never showed it: a `->then` on an already-done
Future returns the callback's own Future, which ends in the `Future::IO` poll
chain, and that one can `await`.

Core made the class of the waiter the transport's to choose (ADR 0047
addendum 2026-09-28, karr core k256): `PoolBase::_new_waiter`, asked once per
queued caller, and `PoolBase::_withdraw_waiter`, which takes a waiter out of the
queue without settling it.

Making the waiter able to wait is not enough. A blocking wait can *die*: the
built-in `Future::IO` implementation refuses to run a loop with nothing on it
(`Cowardly refusing to sit idle and do nothing`). The case is real and cannot be
told from a legitimate wait beforehand — a sync call made inside a `txn_do`
block of a pool of one, whose only connection the caller itself holds. Core turns
the death into a `ROLLBACK`; the waiter was still queued, so the release of the
finalizer handed the connection to a Future nobody reads (*lost a sequence
Future*), and the pool of one was wedged for good.

An earlier attempt (the stopped work-in-progress on this card) wrapped core's
`_acquire_slot`, spliced core's private `_waiters` and decided heuristically,
before and during the wait, when it could not end. It refused waits that were
legitimate (a transaction elsewhere between statements) and depended on core
internals. It is not what was decided.

## Decision

1. **The pool's waiter is `DBIO::Async::Future`**, made by
   `DBIO::Async::Pool::_new_waiter` (core's seam): a `Future` subclass that
   carries a weak mark of its pool and its waiter along every `->new`, the way
   `IO::Async::Future` carries its loop. Its `await` drives `Future::IO` on the
   implementation that is loaded: a pending Future of that implementation's own
   class is cloned from one of its own (`Future::IO->sleep(0)->new`), resolved
   when the awaited Future settles, and awaited. Nothing is hard-coded to one
   implementation, and no event loop is required (ADR 0004).
2. **A blocking wait that dies takes its waiter back.** If the implementation
   dies while `await` runs, the waiter is withdrawn through core's
   `_withdraw_waiter` — `$waiter->fail($error) if $pool->_withdraw_waiter($waiter)`
   — and the error goes on to the caller unchanged. The connection is then
   never offered to a dead waiter.
3. **Nothing else changes.** Async callers never `await`; the pool's
   `future_class` stays `Future`; no heuristic decides whether a wait "can"
   end; the transport is not asked about connections in flight.

## Consequences

- A sync call with the pool exhausted waits for its turn and gets its answer,
  on the built-in implementation and on IO::Async (`t/35`, `t/36`).
- The unresolvable wait dies on the built-in implementation with the loop's own
  words, and leaves the pool usable (`t/35`). Under a real loop (IO::Async,
  AnyEvent, ...) the same case **hangs**: the loop is never asked to stop, and
  the implementation has no "nothing to do" signal. Before, it croaked at once.
  This is the cost of waiting and was accepted with the decision; a caller that
  holds the pool's only connection and then calls a sync method has a bug,
  whatever the loop.
- The reentrancy limit of `Future::IO::Impl::IOAsync` (karr k37 / k38) is not
  worked around, here as elsewhere in `lib/`.
- `await` makes a `Future::IO->sleep(0)` per call and lets it elapse (this
  dist cancels a Future in `_let_go` only, `t/13`). Cost: one extra loop turn
  per blocking wait, on a path that blocks anyway.
- The derived Futures carry the mark for as long as they live, after the
  waiter has been served too; withdrawing then finds nothing queued and does
  nothing.
- A driver with its own pool class gets the same by answering `_new_waiter`
  with a `DBIO::Async::Future` marked with its pool.
