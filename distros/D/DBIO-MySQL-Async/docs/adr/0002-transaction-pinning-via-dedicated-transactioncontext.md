# ADR 0002 — Transaction pinning via a dedicated TransactionContext

- Status: accepted
- Date: 2026-06-21
- Tags: async, transactions, pool, pinning, connection-affinity, drivers

## Context

Core ADR 0014 (async storage interface) provides the *seam* for transaction
connection affinity but not the policy: `DBIO::Storage::PoolBase` ships
`acquire_txn` alongside the normal `acquire`, and the core ADR names
`Async::TransactionContext` and "pooled with txn pinning" only as something the
real driver implements. `acquire_txn` is a caller-managed hook: the pool hands out
a connection but does not itself enforce that every statement in the transaction
runs on it, nor that it is held until COMMIT/ROLLBACK. This ADR builds on that core
seam and records the driver-level policy that fills it; it does not restate the
async interface.

The problem is concrete. A pooled async storage normally releases a connection
back to the pool the instant a query's callback fires (`Storage.pm:311-313`,
`_query_async`). Inside a transaction that is fatal: `BEGIN`, the body statements
and `COMMIT` must all execute on the *same* EV::MariaDB connection, and the
connection must not be handed to another caller mid-transaction. The default
release-on-completion behaviour would scatter a transaction's statements across
pool connections.

This driver also previously implemented the transaction by *shallow-copying* the
storage object (`bless { %$self, _txn_mdb => $mdb, _in_txn => 1 }, ref $self`) and
routing through an AUTOLOAD delegate — fragile because AUTOLOAD silently forwards
typos and bypasses `can()`/method checks (karr #2). That approach was dropped in
favour of an explicit context object; this ADR records the surviving design.

## Decision

Pin one connection for the lifetime of a transaction through a dedicated
`DBIO::MySQL::Async::TransactionContext` object, and route every statement in the
transaction body through a *non-releasing* query path.

- **Acquire with pinning.** `txn_do_async` takes the connection from
  `$self->pool->acquire_txn` (`Storage.pm:354`), the core PoolBase pinning seam,
  not the normal `acquire`.
- **Wrap it in a context.** A `TransactionContext` is constructed around the
  pinned handle (`Storage.pm:356-360`); it stores the storage and the pinned `mdb`
  handle (`TransactionContext.pm:9-15`), exposes the handle as `txn_mdb`
  (`TransactionContext.pm:31`), and answers `in_txn` true unconditionally
  (`TransactionContext.pm:47`) versus storage's `in_txn` of `0` (`Storage.pm:523`).
- **Pass the context, not the storage, to the callback.** `txn_do_async` invokes
  the user coderef with the `TransactionContext` as its first argument
  (`Storage.pm:372`), so the callback's `select_async` / `insert_async` / … calls
  land on the context.
- **Explicit delegation, not AUTOLOAD.** The context delegates each public
  async/sync method back to storage by an explicit method list
  (`TransactionContext.pm:67-79`); an unknown method does **not** silently forward.
  Its private `_query_async` routes through `_query_async_pinned`
  (`TransactionContext.pm:57-60`), which runs the query on the pinned handle and
  deliberately does **not** release it (`Storage.pm:321-328`). Contrast
  `_query_async`'s normal release at `Storage.pm:311-313`.
- **Release exactly once, at the boundary.** Only the BEGIN/COMMIT/ROLLBACK
  machinery in `txn_do_async` releases the pinned connection — on BEGIN failure
  (`Storage.pm:367`), on ROLLBACK (`Storage.pm:376`, `401`, `411`) and on COMMIT
  (`Storage.pm:389`, `411`).

The same shape exists in the sibling `dbio-postgresql-async`, which ships its own
`DBIO::PostgreSQL::Async::TransactionContext`; that driver owns its own copy of
this decision in its own ADR 0002. It is named here only to show the pattern is
family-wide, not duplicated as policy.

## Rationale

Connection affinity is non-negotiable for a real transaction over EV::MariaDB, and
the core pool's default is release-on-completion — so *something* per-driver has to
override it. A dedicated context object is the clean way: it makes "we are inside a
transaction" a real object the callback holds, rather than a flag smeared across a
shallow-copied storage, and it localises the one behavioural difference (pin
instead of release) to a single private method (`_query_async_pinned`) while
keeping the entire public surface identical via *explicit* delegation. The earlier
AUTOLOAD form forwarded typos silently; replacing it with an enumerated delegation
list (`TransactionContext.pm:67-79`) was the point of karr #2. Routing through
`acquire_txn` rather than re-implementing pool checkout keeps the pinning policy
here and the pool mechanics in core, exactly where core ADR 0014 put the seam.

This is shipped and unit-pinned (`t/transaction-context.t` asserts the context's
`_query_async` routes through `_query_async_pinned`, that `in_txn` is `1` on the
context and `0` on storage, and that INSERT runs on the pinned `mdb`), hence
**accepted**, not proposed.

## Consequences

- Every statement in a `txn_do_async` body runs on one EV::MariaDB connection,
  which is held out of the pool from BEGIN to COMMIT/ROLLBACK and returned exactly
  once at the boundary. No transaction statement can leak onto a sibling
  connection.
- The context is a thin facade with an *enumerated* delegation list
  (`TransactionContext.pm:67-79`): any new public storage method that a txn
  callback should be able to call must be added to that list, or it will be
  missing on the context — and, by design, will not silently autoload.
- Releasing is owned solely by the transaction boundary code, not by the query
  path. A future refactor of `_query_async_pinned` must preserve the "never
  release" invariant — releasing there would return the connection mid-transaction
  and corrupt the txn.
- The pinning policy depends on core's `acquire_txn` seam (ADR 0014); if PoolBase
  changed `acquire_txn`'s checkout/affinity semantics, this driver's transaction
  isolation would move with it and must be re-verified.
