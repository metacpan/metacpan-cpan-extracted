# ADR 0003 — Loop-free pipe-backed Future, EOF-framed, and its size limit

- Status: accepted
- Date: 2026-06-28
- Tags: async, future, fork, pipe, limits

> **Addendum 2026-09-05 — the premise of the "full `future_class` surface"
> bullet changed; the decision it supports did not.** That bullet argues from
> "the ADR-0029 fallback chain makes `DBIO::Forked::Storage` the *live* async
> backend for every driver". Core has withdrawn ADR 0028 and ADR 0029 and put
> ADR 0030's explicit per-connection mode in their place:
> `DBIO::Forked::Storage` registers the `forked` mode on the core base storage
> class, and is the backend of every connection opened with
> `connect(..., { async => 'forked' })` — not of every driver automatically.
> There is no fallback chain and no auto-selection (see the addendum on
> ADR 0001).
>
> **The requirement is unchanged, and it never depended on that chain.** It
> depends on what core's ResultSet/Row async helpers do once a mode *is* active:
> they read `$storage->future_class` and call `done` / `fail` on it
> (`_rs_run_async` in `DBIO::ResultSet`, `_row_run_async` in `DBIO::Row`), and
> `needs_all` / `and_then` complete the same `future_class` surface core defines
> (`needs_all` is what core's pipeline collection calls in
> `DBIO::Storage::Async`). Under `{ async => 'forked' }` that class is
> `DBIO::Forked::Future`, so it must carry the full surface exactly as decided
> below. A later reader should not treat the withdrawn ADR 0029 as grounds to
> trim it back to the minimal `DBIO::Future` contract.
>
> One rename from the same core change: the class the bullet below calls
> `DBIO::Test::Future` is now `DBIO::Future::Immediate` — the production Future
> of core's `immediate` mode. Read both mentions as naming that class; the
> compatibility claim is otherwise unchanged.

## Context

Core `DBIO::Future` is a *contract* (`then` / `catch` / `get` / `is_ready` /
`is_failed`), not a base class — "async distributions bring their own Future
implementation". `DBIO::Forked` is loop-free (no `Future::IO`) yet must satisfy
that contract, and its result is produced in another process, crossing a pipe.

## Decision

`DBIO::Forked::Future` is a bespoke, loop-free Future over the pipe read fd:

- **`is_ready`** is an EOF-clean non-blocking *drain*: it reads whatever is
  available without blocking and accumulates across calls (`IO::Select->can_read(0)`),
  and is ready only on `sysread == 0` (EOF), at which point it thaws, reaps and
  caches. A bare `can_read(0)` peek would be premature — it goes true as soon as
  the child writes *anything*, not when the result is complete.
- **`get`** blocks to EOF, thaws, `waitpid`-reaps, re-throws on error;
  idempotent (cached).
- **`then` / `catch`** compose *lazily*, loop-free: a derived future stores its
  callbacks + a source ref and resolves synchronously at the first force —
  whether via `get` or via `is_ready`/`is_failed` once the source is ready —
  because without a loop the callback must run at first force. It flattens a
  single returned `DBIO::Forked::Future` (chaining); deeper nesting is a later
  concern. `then` flattens by real-`Future` semantics (a superset of
  `DBIO::Test::Future`'s non-flattening `then`); `and_then` is `then` with
  future-returning intent made explicit.
- **Full `future_class` surface, not just the minimal contract.** Because the
  ADR-0029 fallback chain makes `DBIO::Forked::Storage` the *live* async backend
  for every driver, its `future_class` must answer what core's ResultSet-async
  helpers call — `$storage->future_class->done(@rows)` / `->fail($err)`
  (`ResultSet.pm`). So `DBIO::Forked::Future` provides the fuller
  `DBIO::Test::Future`-compatible surface: the `done` / `fail` / `needs_all`
  class constructors plus `and_then`, not only the minimal `DBIO::Future`
  contract. A settled `done`/`fail` future is a pre-resolved leaf with no child,
  reusing the same resolution machinery. `needs_all` blocks on each input via
  `get` in turn — the children already run in parallel, so wall time is the
  slowest child, not the sum (serial collection is subject to the pipe-buffer
  ceiling above for many large results).
- **EOF-framing**: one frozen blob per child; the child closes its write end and
  the parent reads to EOF. No length prefix, no streaming.

## Consequences

- **Pipe-buffer size limit.** If the blob exceeds the pipe buffer (~64 KB on
  Linux), the child *blocks in the write* until the parent starts reading (at
  `get`/`is_ready`). For "one query → `->get`" this is irrelevant; for "fire many
  `*_async`, do other work, collect later" with large result sets the children
  do not actually run to completion in parallel — they stall in the write. This
  is an inherent limit of Model A + EOF-framing, and a concrete argument for a
  future Model B (worker pool + streaming frames, as in QuickORM's `STH::Fork`).
- **Everything crossing the pipe must be Storable-serializable.** For the CRUD
  ops the child returns plain rows — always serializable. For `txn_do_async` the
  body's *return value* is user-controlled and crosses the pipe the same way, so
  it too must be serializable (plain scalars / array/hash refs), not a live
  `Row`/`ResultSet` (which drags a dead-in-the-parent DB handle along). A
  non-serializable return is caught at `Storable::freeze` in the child and
  surfaced as a failed Future with a clear message, not a corrupt blob.
- `DESTROY` ends an un-collected child the way `cancel` does (SIGTERM, a one
  second grace period polled with `waitpid(WNOHANG)`, then SIGKILL, then reap), so
  no zombies are left and dropping a Future never waits for the database. `cancel`
  does the same on request and fails the Future as cancelled; on a resolved Future
  it does nothing, and only the owning process may call it (karr k27).
- **A leaf future can carry a deadline** (`timeout` to `new`, set by the storage
  from `statement_timeout`). The future checks the clock when it is asked: `get`
  waits on the pipe no longer than the time left, `is_ready`/`is_failed` look at
  the clock before reporting pending. At the deadline an unreadable pipe ends the
  child the way `cancel` does and the future fails with `statement_timeout
  exceeded`; a result that has arrived is taken as it is. Without a caller
  asking, nothing runs the clock (loop-free); the deadline holds for whoever
  collects the result (karr k27).
- `is_ready`/`is_failed` on a derived (`then`/`catch`) future run the callback as
  a side effect at first force. This is the only coherent loop-free semantics
  (the callback has to run *somewhere* without a loop) and runs exactly once.
- A Future belongs to the process that created it (it records `$$` at
  construction). Only that process reads the pipe and reaps the child; in another
  process `get`/`is_ready`/`is_failed` fail with `belongs to process N` and
  `DESTROY` closes and reaps nothing. A derived future follows its source (karr k26).
