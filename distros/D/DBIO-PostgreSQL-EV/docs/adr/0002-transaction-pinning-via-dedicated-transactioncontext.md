# ADR 0002 — Transaction pinning via a dedicated TransactionContext

- Status: accepted
- Date: 2026-06-21
- Tags: async, transactions, pool, pinning, connection-affinity, drivers
- Superseded in part: the driver-owned `TransactionContext` *implementation*
  described below is superseded by core ADR 0030 §4 (see the Amendment); the
  pinning policy itself stands

## Amendment (2026-09-06, karr k32) — the context class is core's, this dist keeps only an alias

The decision this ADR records is in force and unchanged: one connection pinned
for the life of a transaction, every statement in the body routed through a
non-releasing query path, the connection released exactly once at the
BEGIN/COMMIT/ROLLBACK boundary. What is superseded is *where the context object
lives*.

Core ships the generic `DBIO::Storage::Async::TransactionContext` with the
identical surface, plus `_context_active` / `_invalidate` (core ADR 0045) — core
ADR 0030 §4, *One core orchestration, pluggable transports*, lifts the shared
Model-B machinery into `DBIO::Storage::Async` and names "a generic
TransactionContext" among the pieces that move. Core's `txn_do_async` builds it
through two seams the transport fills: `_txn_context_class` and
`_txn_conn_accessor` in `DBIO::PostgreSQL::EV::Storage`.
`DBIO::PostgreSQL::EV::TransactionContext` is therefore no longer an
implementation but a **thin subclass** of that core class, contributing exactly
one method: `txn_pg`, a compatibility alias for the inherited `txn_conn`.

Read as superseded, therefore:

- **The delegation list is core's, not this driver's.** The *Decision* bullet
  about delegating each public method back to storage, and the *Consequences*
  bullet about adding every new one to that list, still describe how the context
  behaves — but the list is maintained in core, and a method missing from it is
  a core ticket, not one here.
- **The constructor key is `txn_conn`, not `pg`.** `_txn_conn_accessor` returns
  core's key now, because the constructor is core's and dies without it. The
  driver-native name survives only as the `txn_pg` read accessor.

**Why the alias is load bearing here, and where this dist differs from its
mirror.** `dbio-mysql-ev` made the same move in its karr k31 and found its
equivalent alias reachable by no live path: core's `deploy_async` gates the
transactional branch on `_use_transactional_ddl`, and MySQL answers 0 on both
the ownerless and the owner-probed path, so `$ctx->txn_conn` was unreachable
there. **PostgreSQL is the opposite case**, measured rather than assumed:
`DBIO::PostgreSQL::Storage->_use_transactional_ddl` answers **1**, so
`deploy_async` really does take its `txn_do_async` branch and really does read
`$ctx->txn_conn`. The k25 fix that added that accessor closed a *live* gap, not
a latent one — and the subclass now inherits the accessor instead of declaring
it. In the other direction, `txn_pg` is not decoration either:
`t/21-deploy-async-live.t` reaches for it to drive `_execute_ddl_async` on the
pinned connection, so removing it would break a live test that no offline run
can see.

**Editorial note on the line references below.** They are left as written, but
they had already drifted from their targets *before* this amendment: in the
pre-k32 file `TransactionContext.pm:31` and `:47` pointed at blank lines,
`:56-59` at the `in_txn` POD rather than `_query_async`, and `:63-74` at POD
rather than the delegations. The house ADR convention is module path plus
method name for exactly this reason; the drift predates k32 and is recorded
here rather than silently repaired.

## Footnote (2026-09-05, karr k31) — the sibling driver has since been renamed

The *Decision* section below names the sibling as `dbio-mysql-async` shipping
`DBIO::MySQL::Async::TransactionContext`. Both names predate the family-wide
`::Async` → `::EV` rename (this repo's ADR 0008, and its MySQL counterpart
`dbio-mysql-ev` ADR 0008): the dist is `dbio-mysql-ev` and the class is
`DBIO::MySQL::EV::TransactionContext`. Only the names moved — the pattern this
ADR points at is unchanged, and the ADR text is left as written.

## Context

Core ADR 0014 (async storage interface) provides the *seam* for transaction
connection affinity but not the policy: `DBIO::Storage::PoolBase` ships
`acquire_txn` (`dbio/lib/DBIO/Storage/PoolBase.pm:142`) alongside the normal
`acquire`, and the core ADR names `Async::TransactionContext` and "pooled with
txn pinning" (ADR 0014, lines 53–56) only as something the real driver
implements. `acquire_txn` is a caller-managed hook: the pool hands out a
connection but does not itself enforce that every statement in the transaction
runs on it, nor that it is held until COMMIT/ROLLBACK. This ADR builds on that
core seam and records the driver-level policy that fills it; it does not restate
the async interface.

The problem is concrete. A pooled async storage normally releases a connection
back to the pool the instant a query's callback fires
(`Storage.pm:299`, `_query_async`). Inside a transaction that is fatal: `BEGIN`,
the body statements and `COMMIT` must all execute on the *same* libpq connection,
and the connection must not be handed to another caller mid-transaction. The
default release-on-completion behaviour would scatter a transaction's statements
across pool connections.

## Decision

Pin one connection for the lifetime of a transaction through a dedicated
`DBIO::PostgreSQL::EV::TransactionContext` object, and route every statement in
the transaction body through a *non-releasing* query path.

- **Acquire with pinning.** `txn_do_async` takes the connection from
  `$self->pool->acquire_txn` (`Storage.pm:361`), the core PoolBase pinning seam,
  not the normal `acquire`.
- **Wrap it in a context.** A `TransactionContext` is constructed around the
  pinned handle (`Storage.pm:363-366`); it stores the storage and the pinned
  `pg` handle (`TransactionContext.pm:9-15`), exposes the handle as `txn_pg`
  (`TransactionContext.pm:31`), and answers `in_txn` true unconditionally
  (`TransactionContext.pm:47`).
- **Pass the context, not the storage, to the callback.** `txn_do_async` invokes
  the user coderef with the `TransactionContext` as its first argument
  (`Storage.pm:378`), so the callback's `select_async` / `insert_async` / … calls
  land on the context.
- **Non-releasing query path.** The context delegates each public async/sync
  method back to storage (`TransactionContext.pm:63-74`), but its private
  `_query_async` routes through `_query_async_pinned`
  (`TransactionContext.pm:56-59`), which runs the query on the pinned handle and
  deliberately does **not** release it (`Storage.pm:322-335`, comment "Do NOT
  release — connection is pinned for the duration of the txn"). Contrast
  `_query_async`'s normal release at `Storage.pm:299`.
- **Release exactly once, at the boundary.** Only the BEGIN/COMMIT/ROLLBACK
  machinery in `txn_do_async` releases the pinned connection — on COMMIT
  (`Storage.pm:395`, `418`), on ROLLBACK (`Storage.pm:383`, `408`) and on BEGIN
  failure (`Storage.pm:373`).

The same shape exists in the sibling `dbio-mysql-async`, which ships its own
`DBIO::MySQL::Async::TransactionContext`; that driver owns its own copy of this
decision in its own ADR. It is named here only to show the pattern is
family-wide, not duplicated as policy.

## Rationale

Connection affinity is non-negotiable for a real transaction over libpq, and the
core pool's default is release-on-completion — so *something* per-driver has to
override it. A dedicated context object is the clean way: it makes "we are inside
a transaction" a real object the callback holds, rather than a flag smeared
across the storage, and it localises the one behavioural difference (pin instead
of release) to a single private method (`_query_async_pinned`) while keeping the
entire public surface identical via delegation. Passing the context to the
callback means existing `*_async` call sites work unchanged inside a transaction —
they just resolve against the pinned handle. Routing through `acquire_txn` rather
than re-implementing pool checkout keeps the pinning policy here and the pool
mechanics in core, exactly where core ADR 0014 put the seam.

This is shipped and integration-tested, hence **accepted**, not proposed.

## Consequences

- Every statement in a `txn_do_async` body runs on one libpq connection, which is
  held out of the pool from BEGIN to COMMIT/ROLLBACK and returned exactly once at
  the boundary. No transaction statement can leak onto a sibling connection.
- The context is a thin facade: its public methods delegate to storage
  (`TransactionContext.pm:63-74`), so any new public storage method that a txn
  callback should be able to call must be added to the delegation list, or it
  will be missing on the context.
- Releasing is owned solely by the transaction boundary code, not by the query
  path. A future refactor of `_query_async_pinned` must preserve the "never
  release" invariant — releasing there would return the connection mid-transaction
  and corrupt the txn.
- The pinning policy depends on core's `acquire_txn` seam (ADR 0014); if PoolBase
  changed `acquire_txn`'s checkout/affinity semantics, this driver's transaction
  isolation would move with it and must be re-verified.
