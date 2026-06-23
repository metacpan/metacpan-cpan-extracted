# ADR 0003 — EV::MariaDB binding; Pool supplies only the connection seam

- Status: accepted
- Date: 2026-06-21
- Tags: async, ev-mariadb, pool, poolbase, no-dbi, drivers

## Context

Every other MySQL/MariaDB path in the family goes through DBI: the synchronous
`dbio-mysql` driver builds on `DBIO::Storage::DBI` and talks to `DBD::mysql`
(or MariaDB's DBD). DBI is blocking by construction — a `$dbh->execute` does not
return until the server replies — so it cannot serve an event-loop application.
For non-blocking MySQL/MariaDB, DBI is not an option; the driver must speak a
native async client.

Separately, core ADR 0014 puts the concrete pool mechanics — idle-list plus
waiter-queue checkout/checkin, capacity-bounded creation, shutdown — in
`DBIO::Storage::PoolBase`, to be *shared* by async drivers rather than
re-implemented per driver. This driver originally carried its own
new/acquire/release/size/shutdown machinery; karr #3 migrated it onto PoolBase
once core shipped it.

## Decision

Bind to **EV::MariaDB** (the MariaDB Connector/C XS wrapper on the EV loop),
bypassing DBI/DBD entirely, and reduce the driver's pool to only the
EV::MariaDB-specific connection seam over core's `DBIO::Storage::PoolBase`.

- **No DBI.** The storage extends `DBIO::Storage::Async` (`Storage.pm:6`), not
  `DBIO::Storage::DBI`. There is no `$dbh`; queries are issued as
  `$mdb->query($sql, $cb)` against an EV::MariaDB handle, with results delivered to
  the callback and wrapped in a `Future` by `QueryExecutor::execute`
  (`QueryExecutor.pm:42-59`).
- **Connection info is named parameters, not a DSN.** Connect info is a hashref of
  EV::MariaDB named parameters (host, user, password, database). The normalizer
  maps the DBI-ism `dbname` to MySQL's `database` and extracts `pool_size`
  (`Storage.pm:115-132`); there is no `dbi:mysql:` DSN string to parse.
- **Pool inherits PoolBase; supplies only two hooks.** `DBIO::MySQL::Async::Pool`
  is `use base 'DBIO::Storage::PoolBase'` (`Pool.pm:6`) and implements exactly two
  methods: `_create_connection($conninfo)` builds one `EV::MariaDB->new(...)` from
  the already-normalized connect info (`Pool.pm:42-52`), and
  `_shutdown_connection($mdb)` calls `$mdb->close_async` (`Pool.pm:61-64`).
  Acquire/release/waiter-queue/capacity/shutdown all come from PoolBase; the pool
  does **not** push the connection onto `_connections` itself — PoolBase tracks it.

## Rationale

The driver exists *because* DBI cannot be non-blocking; choosing EV::MariaDB is the
whole premise, not an incidental implementation detail. Speaking the MariaDB C
client directly is what lets a query return a `Future` that resolves on the event
loop instead of blocking a thread. Using named connection parameters rather than a
DSN follows the native client's own interface — EV::MariaDB takes host/user/etc.
directly — and avoids round-tripping through a `dbi:mysql:` string the native layer
would only have to take apart again.

Reducing the pool to two hooks over PoolBase is the direct payoff of core ADR
0014's "reuse `DBIO::Storage::PoolBase` for pooling": the subtle parts (the waiter
queue that resolves a pending acquire when a connection is released, capacity
bounding, orderly shutdown) live once in core and are shared with
`dbio-postgresql-async`, while each driver supplies only the few lines that are
genuinely engine-specific — `EV::MariaDB->new` vs `EV::Pg->new`, `close_async` vs
the Pg close. karr #3 is exactly this migration; karr #4 removed the last dead
self-managed pool code (`execute_on_conn`) left over from before it.

This is shipped and pinned (`t/pool-future-queue.t` exercises the PoolBase
acquire/release/waiter contract through a mock `_create_connection`), hence
**accepted**, not proposed.

## Consequences

- The driver takes a hard runtime dependency on `EV::MariaDB` (cpanfile requires
  `>= 0.03`) and on the EV event loop; it has no DBI/DBD dependency at all.
- All pool checkout/checkin/capacity/shutdown behaviour is owned by core
  `DBIO::Storage::PoolBase`. A change to those mechanics lands in core and reaches
  this driver for free — and a regression there would surface here; the pool's own
  responsibility is confined to `_create_connection`/`_shutdown_connection`.
- Connect info is EV::MariaDB-shaped (named params), not a DSN. Code or docs that
  assume a `dbi:mysql:` string do not apply; the `dbname`→`database` and
  `pool_size` normalization is the one place that bridges DBI-style input
  (`Storage.pm:115-132`).
- A new behaviour the pool needs (e.g. per-connection setup on create) belongs in
  the two seam methods, not in re-introduced pool bookkeeping — re-adding an
  acquire/release path here would duplicate PoolBase and was the dead-code class
  removed in karr #4.
