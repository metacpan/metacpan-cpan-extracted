# ADR 0003 — Loop-free pipe-backed Future, EOF-framed, and its size limit

- Status: accepted
- Date: 2026-06-28
- Tags: async, future, fork, pipe, limits

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
- `DESTROY` reaps an un-collected child (blocking `waitpid`) so no zombies are
  left; trade-off: a pathologically stuck child can block at GC time.
- `is_ready`/`is_failed` on a derived (`then`/`catch`) future run the callback as
  a side effect at first force. This is the only coherent loop-free semantics
  (the callback has to run *somewhere* without a loop) and runs exactly once.
