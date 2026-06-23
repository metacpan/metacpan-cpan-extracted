# ADR 0001 — Sync methods block the event loop via `->get`

- Status: accepted
- Date: 2026-06-21
- Tags: async, future, storage, sync-degrade, drivers

## Context

Core ADR 0014 (async storage interface) establishes the *other* direction of
the async/sync bridge: on plain synchronous storage, every `*_async` call
degrades to an immediately-resolved Future (`eval` the sync op, wrap in
`future_class->done/fail`). That makes Future-shaped application code run
unchanged on a non-event-loop storage. This ADR builds on that contract and does
not restate it; it records the *reverse* degrade, which is a driver concern core
explicitly leaves to the real non-blocking dists.

`DBIO::PostgreSQL::Async::Storage` is a genuinely non-blocking driver: its
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
(`lib/DBIO/PostgreSQL/Async/Storage.pm:649-677`): `select`, `select_single`,
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
