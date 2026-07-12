# ADR 0002 — Transaction pinning via a dedicated TransactionContext

- Status: accepted
- Date: 2026-06-28
- Tags: async, transactions, pool, pinning, connection-affinity, generic
- Origin: re-homed and generalized from `dbio-postgresql-async` ADR 0002 (same
  decision, DB-agnostic framing; the per-driver `txn_pg`/`txn_mdb` accessors
  collapse to a unified `txn_conn`).

## Context

Core ADR 0014 (async storage interface) provides the *seam* for transaction
connection affinity but not the policy: `DBIO::Storage::PoolBase` ships
`acquire_txn` alongside the normal `acquire`, and the core ADR names
`Async::TransactionContext` and "pooled with txn pinning" only as something the
real driver implements. `acquire_txn` is a caller-managed hook: the pool hands
out a connection but does not itself enforce that every statement in the
transaction runs on it, nor that it is held until COMMIT/ROLLBACK. This ADR
builds on that core seam and records the generic policy that fills it; it does
not restate the async interface.

The problem is concrete. A pooled async storage normally releases a connection
back to the pool the instant a query's Future completes. Inside a transaction
that is fatal: `BEGIN`, the body statements and `COMMIT` must all execute on the
*same* connection, and the connection must not be handed to another caller
mid-transaction. The default release-on-completion behaviour would scatter a
transaction's statements across pool connections.

## Decision

Pin one connection for the lifetime of a transaction through a dedicated
`DBIO::Async::TransactionContext` object, and route every statement in the
transaction body through a *non-releasing* query path.

- **Acquire with pinning.** `txn_do_async` takes the connection from
  `$self->pool->acquire_txn`, the core PoolBase pinning seam, not the normal
  `acquire`.
- **Wrap it in a context.** A `TransactionContext` is constructed around the
  pinned handle; it stores the storage and the pinned connection handle, exposes
  the handle via a unified `txn_conn` accessor (each driver's context subclass
  may tighten this to a typed accessor, but the generic name is `txn_conn`), and
  answers `in_txn` true unconditionally.
- **Pass the context, not the storage, to the callback.** `txn_do_async`
  invokes the user coderef with the `TransactionContext` as its first argument,
  so the callback's `select_async` / `insert_async` / … calls land on the
  context.
- **Non-releasing query path.** The context delegates each public async/sync
  method back to storage, but its private `_query_async` routes through
  `_query_async_pinned`, which runs the query on the pinned handle and
  deliberately does **not** release it. Contrast the normal release in the
  pooled `_query_async`.
- **Release exactly once, at the boundary.** Only the BEGIN/COMMIT/ROLLBACK
  machinery in `txn_do_async` releases the pinned connection — on COMMIT, on
  ROLLBACK and on BEGIN failure.

## Rationale

Connection affinity is non-negotiable for a real transaction, and the core
pool's default is release-on-completion — so *something* has to override it. A
dedicated context object is the clean way: it makes "we are inside a
transaction" a real object the callback holds, rather than a flag smeared across
the storage, and it localises the one behavioural difference (pin instead of
release) to a single private method (`_query_async_pinned`) while keeping the
entire public surface identical via delegation. Passing the context to the
callback means existing `*_async` call sites work unchanged inside a
transaction — they just resolve against the pinned handle. Routing through
`acquire_txn` rather than re-implementing pool checkout keeps the pinning policy
here and the pool mechanics in core, exactly where core ADR 0014 put the seam.

The unified `txn_conn` accessor replaces the per-driver `txn_pg` / `txn_mdb`
names of the original implementations; a driver subclass may expose a typed
alias, but the generic context speaks one name.

## Consequences

- Every statement in a `txn_do_async` body runs on one connection, which is held
  out of the pool from BEGIN to COMMIT/ROLLBACK and returned exactly once at the
  boundary. No transaction statement can leak onto a sibling connection.
- The context is a thin facade: its public methods delegate to storage, so any
  new public storage method that a txn callback should be able to call must be
  added to the delegation list, or it will be missing on the context.
- Releasing is owned solely by the transaction boundary code, not by the query
  path. A future refactor of `_query_async_pinned` must preserve the "never
  release" invariant — releasing there would return the connection
  mid-transaction and corrupt the txn.
- The pinning policy depends on core's `acquire_txn` seam (ADR 0014); if
  PoolBase changed `acquire_txn`'s checkout/affinity semantics, this layer's
  transaction isolation would move with it and must be re-verified.
