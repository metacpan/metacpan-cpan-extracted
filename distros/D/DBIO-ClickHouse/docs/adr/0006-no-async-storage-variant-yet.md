# ADR 0006 — No async storage variant yet, and what would justify one

- Status: accepted
- Date: 2026-07-26

## Context

Two siblings in the family ship an async storage next to their sync driver:
`dbio-mysql-ev` and `dbio-postgresql-ev`. The question this ADR settles is
whether ClickHouse-over-the-MySQL-wire warrants the same, and it is worth
settling explicitly rather than leaving as an open "maybe later", because the
argument *for* it is stronger here than for either sibling.

**The transport can do it.** `DBD::MariaDB` (1.24) implements asynchronous
queries: `mariadb_async` on `prepare`/`do`, plus `mariadb_async_ready()`,
`mariadb_async_result()` and — the part that matters — `mariadb_sockfd()`,
which hands out the file descriptor an event loop needs. The constraint is one
asynchronous query per connection, which is why `dbio-mysql-ev` carries a pool.
Nothing about that machinery is MySQL-specific: ClickHouse serves the same wire
protocol on port 9004, so the same route is open.

**The shape is known.** `dbio-mysql-ev` is ~1400 lines over `DBIO::Storage::Async`
(core infrastructure, already there): Storage, Pool, QueryExecutor,
ConnectInfo, TransactionContext, TestHarness. It shares the SQLMaker with the
sync driver, which this dist could do too.

**The workload argues for it.** Async pays off in proportion to how long a
query blocks. MySQL's OLTP queries are typically short; ClickHouse's OLAP
queries are the long, expensive, seconds-to-minutes kind. On the merits of
latency alone, ClickHouse is a *better* candidate for an event-loop storage
than the drivers that already have one.

Against that:

- **One of the sibling's six components is meaningless here.**
  `TransactionContext` exists to pin a connection for the duration of a
  transaction. ClickHouse has no transactions (ADR 0003), so that component
  would either vanish or become another lying API — and pinning is exactly
  where an async storage's complexity concentrates.
- **The sync driver is not yet verified against a real server.** Every layer in
  this dist — DDL, introspect, diff, deploy, insert, mutations — currently
  rests on offline tests plus documented assumptions about what the MySQL wire
  actually carries (does `SHOW CREATE TABLE` report `Bool` or `UInt8`, do
  placeholders work in `LIMIT`, does `system.columns` expose `default_kind`
  over this transport). Building a second storage on top of unverified
  assumptions doubles the surface that a live run would invalidate.
- **ClickHouse already solves part of the problem server-side.** `async_insert`
  (documented on the storage) makes the server do the batching, which removes
  the most common reason an application would reach for a non-blocking write
  path in the first place.

The HTTP interface (port 8123) was considered as an alternative async
transport. It would mean leaving `DBIO::Storage::DBI` and DBI entirely — a
separate protocol implementation rather than a storage variant — so it is not a
cheaper route to the same thing, and the MySQL wire has no deficiency that
would force it.

## Decision

**No async ClickHouse storage for now.** The question is not rejected on the
merits; it is sequenced behind the sync driver's live verification.

A `dbio-clickhouse-ev` becomes worth building when all of the following hold:

1. The live suite (karr k8) has run against a real server and the assumptions
   listed in it are confirmed — in particular that `mariadb_sockfd()` and the
   async result cycle behave against ClickHouse's MySQL-wire implementation and
   not merely against MySQL.
2. There is a real workload asking for it — concurrent long-running analytical
   queries in an event-loop application — rather than symmetry with the other
   `-ev` dists.
3. The open correctness tickets on this board are closed, so the async variant
   inherits settled semantics instead of forking them.

## Consequences

- The `-ch` shortcut and `DBIO::ClickHouse::Storage` stay the only entry
  points; there is no `ev` async mode registered for ClickHouse, and code
  looking for one gets nothing rather than a half-honest implementation.
- When the variant is built, it should reuse this dist's SQLMaker the way
  `dbio-mysql-ev` reuses `DBIO::MySQL::SQLMaker`, and it should **not** port
  `TransactionContext`. Connection pinning for ClickHouse has no transactional
  justification; if pinning turns out to be needed, it needs its own reason.
- Deferring costs little: `DBIO::Storage::Async` is core infrastructure and is
  not going away, and the sync storage does not need to be shaped differently
  today to keep the option open.
