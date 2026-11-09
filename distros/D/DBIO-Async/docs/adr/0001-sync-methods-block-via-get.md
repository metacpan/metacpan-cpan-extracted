# ADR 0001 — Sync methods block via `->get`

- Status: accepted
- Date: 2026-06-28
- Tags: async, future, storage, sync-degrade, generic
- Origin: re-homed and generalized from `dbio-postgresql-async` ADR 0001 (same
  decision, DB-agnostic framing).

## Amendment (2026-09-05, k14) — the decision stands; its implementation is core's since ADR 0030 §4

Nothing below is retracted: a sync storage method still *is* its async sibling
run to completion, and `future_class` still is CPAN `Future`. What moved is
where that is written. Core ADR 0030 §4 lifted the Model-B orchestration into
`DBIO::Storage::Async`, which is where the one-line wrappers now live — and
there are seven of them, not six: `select`, `select_single`, `insert`, `update`,
`delete`, `txn_do` and `deploy`, the last of which this ADR never listed.
`DBIO::Async::Storage` writes none of them and inherits all seven, so the
*Decision* reads as a property of the class a `future_io` adapter inherits from,
not of a file in this dist.

The same is true of the second paragraph: the sync wrappers a `txn_do_async`
callback reaches for belong to core's generic
`DBIO::Storage::Async::TransactionContext`. `DBIO::Async::TransactionContext` is
an empty subclass that exists to be *named* — by `_txn_context_class` in
`DBIO::Async::Storage`, and by the driver adapters and tests that refer to it.

What this dist still owns is the half the *Consequences* hinge on: `future_class`
is defined here, in `DBIO::Async::Storage`, and still answers `'Future'`. The
coupling recorded there — the sync wrappers require `future_class->get` to have
blocking semantics — is therefore ours to keep, and it is the reason a
`future_io` transport may not swap in a promise type whose `->get` does not
block.

One name is stale rather than wrong: core's no-loop Future class is
`DBIO::Future::Immediate`, not `DBIO::Test::Future`. Core ADR 0030 turned the
former silent degrade into the deliberately named `immediate` mode and renamed
the class with it; the *Consequences* sentence contrasting it with the real
`Future` still says exactly what it meant to say.

## Amendment (2026-10-09, k30) — `->get` on a wait for the pool drives Future::IO

With the pool exhausted the sync call is queued on a pool waiter, and `->get` on
a plain pending `Future` croaks. The pool's waiter is now `DBIO::Async::Future`,
whose `await` drives `Future::IO`, and a wait that dies withdraws its waiter:
see ADR 0008. The decision stands; this is the case it did not cover.

## Context

Core ADR 0014 (async storage interface) establishes the *other* direction of the
async/sync bridge: on plain synchronous storage, every `*_async` call degrades to
an immediately-resolved Future (`eval` the sync op, wrap in
`future_class->done/fail`). That makes Future-shaped application code run
unchanged on a non-event-loop storage. This ADR builds on that contract and does
not restate it; it records the *reverse* degrade, which is a driver concern core
explicitly leaves to the real non-blocking dists.

A driver that subclasses `DBIO::Async::Storage` is genuinely non-blocking: its
primitives (`select_async`, `insert_async`, `txn_do_async`, …) are the real
event-loop operations and return a `Future` that resolves only when the driver's
non-blocking client completes the IO. But the rest of DBIO — `$rs->all`,
`$row->update`, scripts, migrations, `Deploy` — still calls the *synchronous*
storage methods `select`, `insert`, `update`, `delete`, `txn_do`. On a
sync-native storage those are the real implementation; here there is no
synchronous implementation to fall back to, only the async one.

## Decision

Implement every synchronous storage method as a one-line wrapper that calls its
async sibling and blocks on the resulting Future with `->get`: `select`,
`select_single`, `insert`, `update`, `delete`, `txn_do` each are
`return $self->..._async(@_)->get`. `future_class` is `'Future'`, so `->get` is
`Future.pm`'s blocking get — it spins the event loop until the Future is ready,
then returns its value (or rethrows its failure). The async path is the single
source of truth; the sync path is a thin blocking adapter over it.

The `DBIO::Async::TransactionContext` exposes the same sync wrappers, so a
`txn_do_async` callback that reaches for a sync method gets the identical
blocking behaviour.

## Rationale

This is the mirror image of core ADR 0014's sync-degrade and it keeps the
skeleton on *one* implementation of each operation instead of two. A
non-blocking driver that also hand-wrote synchronous query code would have two
code paths to keep in agreement; routing sync through `async->get` guarantees
they cannot diverge — the sync method is, by construction, the async method run
to completion. It also means the DB-specific behaviours a driver supplies via
its seam hooks (e.g. PostgreSQL's `RETURNING *`, pinned-connection transactions,
the driver's SQLMaker) apply uniformly to sync *and* async callers, because the
sync call literally is the async call.

The cost — `->get` blocks the event loop while the query runs — is accepted on
purpose. Calling a sync method from inside a running event-loop application is a
category error the user has opted into; the methods exist for scripts,
migrations and `Deploy`, where blocking is exactly what is wanted.

## Consequences

- Sync and async results are identical by construction: `select` returns what
  `select_async(...)->get` returns, a failure in the Future is rethrown as a die
  from the sync call. There is no second implementation to drift.
- Calling a sync method (`->all`, `->update`, `txn_do`) from inside an active
  event loop blocks that loop until the query completes. This is acceptable for
  scripts/migrations and a footgun in a live event-loop app — by design, not an
  oversight.
- `future_class` is the real CPAN `Future`, not core's `DBIO::Test::Future`;
  `->get` therefore drives a real event loop. A driver that swapped
  `future_class` for a promise type whose `->get` did not block would break
  every sync method here, so the sync wrappers are coupled to
  `future_class->get` having blocking semantics.
