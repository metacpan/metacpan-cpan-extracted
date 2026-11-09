# ADR 0002 — Transaction pinning via a dedicated TransactionContext

- Status: accepted
- Date: 2026-06-21
- Tags: async, transactions, pool, pinning, connection-affinity, drivers
- Superseded in part: the driver-owned `TransactionContext` *implementation*
  described below is superseded by core ADR 0030 §4 (see the Amendment); the
  pinning policy itself stands

## Amendment (2026-09-06, karr k31) — the context class is core's, this dist keeps only an alias

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
`_txn_conn_accessor` in `DBIO::MySQL::EV::Storage`.
`DBIO::MySQL::EV::TransactionContext` is therefore no longer an implementation
but a **thin subclass** of that core class, contributing exactly one method:
`txn_mdb`, a compatibility alias for the inherited `txn_conn`.

Read as superseded, therefore:

- **The enumerated delegation list is core's, not this driver's.** The *Decision*
  bullet "Explicit delegation, not AUTOLOAD" and the *Consequences* bullet about
  adding each new public method to that list still describe how the context
  behaves — but the list is maintained in core, and a method missing from it is
  a core ticket, not one here. What karr k2 found (AUTOLOAD forwards typos
  silently, bypassing `can()`) is what core's enumerated list encodes.
- **The constructor key is `txn_conn`, not `mdb`.** `_txn_conn_accessor` returns
  core's key now. The private `mdb` key left the context with no `txn_conn`
  accessor at all — the very accessor core's own `deploy_async` reads in its
  transactional branch. That was latent here rather than live: MySQL COMMITs DDL
  implicitly, so `deploy_async` takes its non-transactional branch (ADR 0026)
  and never asks. Latent, but a real hole in the contract.
- **The `TransactionContext.pm:NN` references below point at code this
  distribution no longer contains.** They described the copy; those methods are
  core's. (Line-numbered references are pre-house-rule anyway — new ones name
  module plus method.)

Gained for free by inheriting: `_context_active` / `_invalidate`, which a
context-bound `DBIO::ResultSet` / `DBIO::Row` / `DBIO::ResultSetColumn` consults
before routing an `*_async` op onto the context. Core probes it with `can()`, so
the copy was behaviourally equivalent today — the drift at the next core step,
not a live bug, is why the copy stopped being worth keeping.

The sibling paragraph below still holds as written: `dbio-postgresql-ev` owns
its own copy and its own ADR 0002. Its karr k32 is the mirror of this change and
was still open when this amendment was written.

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
typos and bypasses `can()`/method checks (karr k2). That approach was dropped in
favour of an explicit context object; this ADR records the surviving design.

## Decision

Pin one connection for the lifetime of a transaction through a dedicated
`DBIO::MySQL::EV::TransactionContext` object, and route every statement in the
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

> **Naming footnote.** Those are the sibling's pre-rename names, as they stood
> when this ADR was written. It is now `dbio-postgresql-ev` and the class is
> `DBIO::PostgreSQL::EV::TransactionContext` — the PostgreSQL half of the same
> `::Async` → `::EV` move this dist records in
> [ADR 0008](0008-rename-distribution-and-namespace-to-ev.md), whose
> Consequences deliberately left cross-repo references untouched because that
> half had not landed yet. It has since. The decision recorded above is
> unaffected: only the sibling's names moved.

## Rationale

Connection affinity is non-negotiable for a real transaction over EV::MariaDB, and
the core pool's default is release-on-completion — so *something* per-driver has to
override it. A dedicated context object is the clean way: it makes "we are inside a
transaction" a real object the callback holds, rather than a flag smeared across a
shallow-copied storage, and it localises the one behavioural difference (pin
instead of release) to a single private method (`_query_async_pinned`) while
keeping the entire public surface identical via *explicit* delegation. The earlier
AUTOLOAD form forwarded typos silently; replacing it with an enumerated delegation
list (`TransactionContext.pm:67-79`) was the point of karr k2. Routing through
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

## Amendment (2026-10-06, karr k74) — the transaction's ROLLBACK waits for the statements in flight, and a ROLLBACK or COMMIT that fails retires the connection

The pinning policy is unchanged; what it lacked is a rule for how a transaction
*ends* on its pinned connection. EV::MariaDB refuses a `query` while a `prepare`
or an `execute` is in flight, and a statement with bind values is both. When the
coderef died, its Future failed, or a statement was cancelled with such a
statement on the wire, core's `ROLLBACK` was refused: no `ROLLBACK` reached the
server, and the connection went back to the pool with the transaction open
(live measurement, `t/37-txn-rollback-refused-live.t`, MySQL 8.0.30 and MariaDB
11.8.8 alike). The decision, kept in this transport (core stays as it is):

- the invariant: **a connection with an open transaction never goes back to the
  pool**;
- the `ROLLBACK` of a pinned connection is queued behind the statements in
  flight on it (`QueryExecutor::execute_when_idle`) and handed over from the
  callback that settles the last of them — `close_stmt` is never in flight, a
  query right behind it is taken;
- a `ROLLBACK` that fails for any reason retires its connection
  (`PoolBase::_mark_connection_dead`) instead of releasing it;
- a `COMMIT` that fails retires its connection the same way. It is not queued
  -- core sends it only after every statement of the transaction's context has
  settled -- but whether the server failed it or EV::MariaDB refused to take it,
  nobody knows whether the transaction is still open, and the invariant does
  not ask. Before this a failed `COMMIT` left the connection idle in the pool,
  and the next `BEGIN` on it committed what the caller had been told was not
  committed (`t/36-cancel-in-flight-mock.t`, section 13).

The cost is that the transaction ends after the statement in flight has been
answered. The alternative of a cancel that reaches the server was not taken
(k73: a cancel does not stop the statement on the server).

## Amendment (2026-10-25, karr k81) — the wait has a limit, and every statement queues behind a prepare/execute

Two things the k74 amendment left open, decided by the maintainer on
2026-10-25:

- **The ROLLBACK's wait ends.** A statement in flight whose answer never comes
  would keep the queued `ROLLBACK`, the transaction and its connection waiting
  for ever. The wait is bounded by `rollback_wait_timeout` (a storage attribute,
  seconds, default 30, `0`/`undef` = unlimited). When it is up the `ROLLBACK` is
  not sent, the connection is retired like one whose `ROLLBACK` failed (it may
  still hold the transaction), and the transaction's Future fails with a
  `DBIO::Exception` naming the wait, beside the error that made it fail.
- **Every statement queues, not only the `ROLLBACK`.** EV::MariaDB refuses any
  `query` while a `prepare` or an `execute` is in flight, so on a pinned
  connection every statement issued behind such a statement — a `COMMIT`
  included — waits for it (`QueryExecutor::execute_after_exclusive`), in the
  order issued. Behind plain queries nothing waits: they are pipelined as before
  (`t/36-cancel-in-flight-mock.t`, section 6). The queue stays strictly ordered
  while something is in flight; a statement issued from the callback of one that
  just settled, with nothing in flight, goes out at once, so the `LAST_INSERT_ID()`
  of an insert still precedes a waiting `ROLLBACK`.

Pinned by `t/36-cancel-in-flight-mock.t` (14, 15) and
`t/57-rollback-wait-timeout-live.t`.
