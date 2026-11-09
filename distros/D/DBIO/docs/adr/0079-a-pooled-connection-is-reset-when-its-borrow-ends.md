# ADR 0079 — A pooled connection is reset when its borrow ends

- Status: accepted (coordinator decision of 2026-10-30, karr k398, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: async, pool, session, reset, connect-options, relates-0078

## Context

An async storage lends the connections of its pool (`DBIO::Storage::PoolBase`)
to one borrow at a time: a statement, a transaction or a pipeline. A session
holds state a statement can set for the whole session: role, session
authorization, configuration values, search path, isolation level, temporary
tables, prepared statements, advisory locks.

## Decision

1. **The session belongs to the borrow.** The state of one borrow is not the
   state of the next. A borrow's session state stays with its borrower.
2. **`release` stays the synchronous return of ownership; the pool then resets.**
   The pool puts the connection into the state `resetting`, ends its lease, and
   makes a second release of it a no-op. The connection keeps its slot, so the
   pool size stays counted. The pool holds the Future of the reset. When it is
   done, the connection goes to the oldest waiter still waiting, or to the idle
   list. When it fails, or does not answer within `reset_timeout`, the connection
   is retired and the next borrower gets a fresh one. There is no option to
   switch the reset off.
3. **The seam is `_reset_pool_connection($conn)` of the async storage.** It
   returns a Future. Success means the connection is as one just spawned,
   connect actions included; failure means retire. The core default fails: a
   transport without a reset of its own retires the connection at the end of
   each borrow. A transport whose server can reset a session overrides it.
4. **The reset is at the lending boundary.** It runs at the end of a borrow, of
   a transaction (after COMMIT or ROLLBACK) and of a pipeline. Statements pinned
   to a connection inside a borrow do not reset it. The connection of a `listen`
   lies outside the pool and is not reset.
5. **`reset_timeout`** (seconds, default 10, `0` for no bound) is a declared
   async option (ADR 0078 §6). It is measured by the storage's `_delay` seam.
6. **A running reset is voided by shutdown, by fork detection and by a
   retirement.** Its Future is cancelled (an inherited one is left to its
   process), a late answer changes nothing, and shutdown sends no disconnect
   statement beside it.

## Rationale

A connection pool shares sessions between callers only if the sessions are
equal for each of them. Resetting in the pool, at the one place connections
change borrowers, gives every transport the same guarantee, and a default that
retires gives it to a transport that has no reset yet.

## Consequences

- A transport without `_reset_pool_connection` connects once per borrow.
- Error handling of a failed reset is the retirement of the connection; no
  message carries SQL, binds or values.
- A pool without an owning storage has no session to reset and hands
  connections on directly.
