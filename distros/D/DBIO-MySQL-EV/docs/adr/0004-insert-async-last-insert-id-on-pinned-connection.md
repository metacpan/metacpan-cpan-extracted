# ADR 0004 — `insert_async` reads the key via `LAST_INSERT_ID()` on the same connection

- Status: accepted
- Date: 2026-06-21
- Tags: async, insert, last-insert-id, dml, connection-affinity, drivers

## Context

DBIO's higher layers expect an `insert` to give back the server-assigned
auto-increment key. The sibling `dbio-postgresql-async` solves this by appending
`RETURNING *` to the INSERT and resolving the Future straight from the row libpq
returns (its ADR 0004) — one statement, no second round-trip. MySQL/MariaDB has
**no `RETURNING`** on the relevant server versions, so that route is unavailable
here. The auto-increment value has to be read with a separate
`SELECT LAST_INSERT_ID()`.

`LAST_INSERT_ID()` is *session-scoped*: it returns the last auto-increment
generated on the **same connection**. In a pooled async driver this is a trap — if
the INSERT and the `SELECT LAST_INSERT_ID()` ran on different pool connections, or
if the connection were released back into the pool and re-acquired by another
caller between the two statements, the returned id would be wrong or another
session's. The naive shapes are race conditions: releasing the connection right
after the INSERT *starts* (so it is reusable while the key read is still in
flight), and dispatching the key read as a fire-and-forget side-effect so the
caller's Future resolves before the id is actually known (karr #5).

## Decision

`insert_async` acquires one connection, runs the INSERT on it, then runs
`SELECT LAST_INSERT_ID()` **on that same connection** via the non-releasing pinned
path, chaining the two so the caller's Future does not resolve until the key is
read; the connection is released only after the key read settles (and on failure),
never before (`Storage.pm:254-272`).

- Acquire once: `my $mdb = $self->pool->acquire` (`Storage.pm:258`).
- Run the INSERT through the executor on `$mdb`, then `->then` into the key read
  (`Storage.pm:260-261`): `_query_async_pinned($mdb, 'SELECT LAST_INSERT_ID()', [])`
  — the *pinned* path (`Storage.pm:321-328`) runs on the same handle and does not
  release it.
- Store the id from the key-read result into `_last_insert_id`
  (`Storage.pm:262-265`); `last_insert_id` returns it (`Storage.pm:535-538`).
- Release the connection in the key read's `on_ready` — *after* it settles — and
  only when not inside a transaction (`Storage.pm:266`,
  `unless $self->in_txn`); catch an INSERT failure and release there too
  (`Storage.pm:268-271`), since `on_done` never fires on a failed Future.
- Inside `txn_do_async` the same INSERT-then-LII shape runs on the pinned txn
  connection and does **not** release (the `TransactionContext::insert_async`
  variant, `TransactionContext.pm:89-103`) — the transaction owns the lifecycle.

## Rationale

Because MySQL has no `RETURNING`, the key *must* come from a second statement, and
because `LAST_INSERT_ID()` is per-session that statement *must* be the same
connection as the INSERT — this is not a performance choice, it is correctness. The
chaining (`->then`, key read's `on_ready` for release) is what makes both true at
once: the connection is pinned across the pair and only handed back after the id is
read, so no other caller can interpose an INSERT on it and poison
`LAST_INSERT_ID()`, and the caller's Future carries a settled, correct id. This is
precisely the fix recorded in karr #5 — before it, the connection was released
after the INSERT was merely *started*, and the key read was a fire-and-forget
side-effect, making `last_insert_id` a race. The failure-release branch exists
because a failed INSERT Future never fires `on_done`, so without an explicit
`catch` the connection would leak.

This is a deliberate divergence from the Pg sibling's `RETURNING *` (its ADR 0004):
same goal — resolve with the server-assigned key — different mechanism, forced by
the engine. It costs a second round-trip the Pg driver avoids; that cost is
unavoidable on MySQL without `RETURNING`.

This is shipped and pinned (`t/transaction-context.t` asserts the INSERT runs on
the pinned `mdb` and the trailing key read settles on the pinned path before the
caller's Future), hence **accepted**, not proposed.

## Consequences

- An async `insert` is two server round-trips (INSERT, then
  `SELECT LAST_INSERT_ID()`), against the Pg driver's one. This is the price of
  MySQL having no `RETURNING`; it is intrinsic, not tunable here.
- The connection is held across the INSERT/key-read pair and released exactly once,
  after the key read settles (`Storage.pm:266`) or on INSERT failure
  (`Storage.pm:269`) — never between the two statements. Any refactor that releases
  earlier reintroduces the karr #5 race: `LAST_INSERT_ID()` could read another
  session's value.
- `last_insert_id` is only valid immediately after the insert Future settles; it is
  stored on the storage instance (`_last_insert_id`), so concurrent inserts on the
  *same storage object* overwrite it — callers should read the key from the insert
  Future's resolution, not race a second insert against the accessor.
- Inside `txn_do_async` the INSERT+LII runs on the pinned txn connection and is not
  released (ADR 0002 owns the lifecycle); the non-transactional path is the only
  one that releases.
