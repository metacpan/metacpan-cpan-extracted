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
new/acquire/release/size/shutdown machinery; karr k3 migrated it onto PoolBase
once core shipped it.

## Decision

Bind to **EV::MariaDB** (the MariaDB Connector/C XS wrapper on the EV loop),
bypassing DBI/DBD entirely, and reduce the driver's pool to only the
EV::MariaDB-specific connection seam over core's `DBIO::Storage::PoolBase`.

- **No DBI.** The storage extends `DBIO::Storage::Async` (`Storage.pm`, `use
  base`), not `DBIO::Storage::DBI`. There is no `$dbh`; queries are issued as
  `$mdb->query($sql, $cb)` against an EV::MariaDB handle, with results delivered to
  the callback and wrapped in a `Future` by
  `DBIO::MySQL::EV::QueryExecutor::execute`.
- **Connection info is named parameters, not a DSN.** Connect info is a hashref of
  EV::MariaDB named parameters (host, user, password, database). The normalizer
  maps the DBI-ism `dbname` to MySQL's `database` and extracts `pool_size`
  (`DBIO::MySQL::EV::Storage::_normalize_async_connect_info`); there is no
  `dbi:mysql:` DSN string to parse.
- **Pool inherits PoolBase; supplies only the EV::MariaDB seam.**
  `DBIO::MySQL::EV::Pool` is `use base 'DBIO::Storage::PoolBase'` and overrides
  exactly six of its methods. Three are the connection seam:
  `_create_connection($conninfo)` shapes the already-normalized connect info
  into named arguments and hands them to core's `_create_ready_connection`;
  `_new_connection(%args)` builds the one `EV::MariaDB->new(...)`;
  `_shutdown_connection($mdb)` calls `$mdb->close_async`. Three answer what only
  this transport knows about its connections, each through a seam core offers
  for it: `_verify_pid` keeps hold of the handles a forked child inherited, for
  the fork guard to finish (ADR 0010, amendment k54); `_new_waiter` marks the
  Future a queued caller waits on (ADR 0001, addendum k53);
  `_idle_connection_alive` says whether an idle connection's session is still
  there before the pool hands it out (ADR 0010, amendment k58).
  Acquire/release/waiter-queue/capacity/shutdown **and the connection-readiness
  gate** all come from PoolBase; the pool does **not** push the connection onto
  `_connections` itself — PoolBase tracks it.

## Rationale

The driver exists *because* DBI cannot be non-blocking; choosing EV::MariaDB is the
whole premise, not an incidental implementation detail. Speaking the MariaDB C
client directly is what lets a query return a `Future` that resolves on the event
loop instead of blocking a thread. Using named connection parameters rather than a
DSN follows the native client's own interface — EV::MariaDB takes host/user/etc.
directly — and avoids round-tripping through a `dbi:mysql:` string the native layer
would only have to take apart again.

Reducing the pool to that seam over PoolBase is the direct payoff of core ADR
0014's "reuse `DBIO::Storage::PoolBase` for pooling": the subtle parts (the waiter
queue that resolves a pending acquire when a connection is released, capacity
bounding, orderly shutdown) live once in core and are shared with
`dbio-postgresql-async`, while each driver supplies only the few lines that are
genuinely engine-specific — `EV::MariaDB->new` vs `EV::Pg->new`, `close_async` vs
the Pg close. karr k3 is exactly this migration; karr k4 removed the last dead
self-managed pool code (`execute_on_conn`) left over from before it.

The connection seam's method count moved twice since this ADR was written, in
both directions. karr k20 added a hand-written `_create_connection` readiness
wiring plus a
`_connection_ready_future` override and a `_new_ev_mariadb` constructor seam, to
fix an `acquire` that handed out handles whose async connect had not finished.
Core then lifted exactly that wiring into PoolBase (`_create_ready_connection`,
the named `_new_connection` seam, and a default `_connection_ready_future` that
honours a registered readiness Future) after finding this driver and
`dbio-postgresql-ev` had written it identically — core karr k158. karr k33 took
the local copies back out. This driver is a **callback-shaped** transport:
`EV::MariaDB->new` accepts `on_connect` and `on_error` as constructor arguments
and installs them before it starts connecting, which is precisely what core's
wiring needs. A **poll-shaped** transport (no connect callbacks, readiness
established by probing) still overrides the seam itself — `dbio-async`'s
`future_io` adapter is that case, and keeps its override.

Three further overrides followed, one per card, and none of them belongs to the
connection seam: `_verify_pid` (karr k54), `_new_waiter` (karr k53) and
`_idle_connection_alive` (karr k58). They do not bring pool bookkeeping back.
Each is a method PoolBase calls at a point core owns — before a forked child
takes the pool over, when a caller has to be queued, before an idle connection
is handed out — and each override only adds what EV::MariaDB's handle or this
transport's Future can tell: `_verify_pid` remembers the inherited handles and
then runs core's, `_new_waiter` marks the Future core made, and
`_idle_connection_alive` answers core's question. The division this ADR decides
is the one they follow: the mechanics stay in core, the engine-specific answer
is given here.

This is shipped and pinned (`t/pool-future-queue.t` exercises the PoolBase
acquire/release/waiter contract through a mock `_create_connection`), hence
**accepted**, not proposed.

## Consequences

- The driver takes a hard runtime dependency on `EV::MariaDB` (cpanfile requires
  `>= 0.08`) and on the EV event loop; it has no DBI/DBD dependency at all.
- All pool checkout/checkin/capacity/shutdown behaviour, and the readiness gate
  `acquire` chains, are owned by core `DBIO::Storage::PoolBase`. A change to those
  mechanics lands in core and reaches this driver for free — and a regression
  there would surface here; the pool's own responsibility is confined to the
  six overrides named in the Decision.
- Connect info is EV::MariaDB-shaped (named params), not a DSN. Code or docs that
  assume a `dbi:mysql:` string do not apply; the `dbname`→`database` and
  `pool_size` normalization is the one place that bridges DBI-style input
  (`DBIO::MySQL::EV::Storage::_normalize_async_connect_info`).
- A new behaviour the pool needs (e.g. per-connection setup on create) belongs in
  the seam methods, not in re-introduced pool bookkeeping — re-adding an
  acquire/release path here would duplicate PoolBase and was the dead-code class
  removed in karr k4. The same holds for readiness: `_create_connection` staying a
  required core hook is what keeps opting into the gate an explicit act, so a pool
  that stops calling `_create_ready_connection` silently loses it
  (`t/08-pool-readiness.t` is what notices).
- **Editorial note (karr k33):** this ADR cited file:line positions
  (`Pool.pm:6`, `Pool.pm:42-52`, `Pool.pm:61-64`, `QueryExecutor.pm:42-59`,
  `Storage.pm:6`, `Storage.pm:115-132`), every one of which had already drifted
  off its target before k33 touched anything, and its "exactly two methods" was
  already wrong by two. Both are corrected above and the citations are now
  module + method, which do not rot with an inserted line.
- **Editorial note (2026-10-04, karr k57):** the count the k33 note corrected
  was three — the connection seam. It has grown by one override per card since:
  `_verify_pid` with karr k54 (2026-09-27), `_new_waiter` with karr k53 and
  `_idle_connection_alive` with karr k58 (both 2026-10-04). The Decision names
  all six and the Rationale says what kind of override the later three are; its
  "moved twice" speaks of the connection seam alone. Checked against the class
  on the day of this note: of the methods `DBIO::MySQL::EV::Pool` defines,
  exactly these six are also defined by `DBIO::Storage::PoolBase`; the rest are
  its own `_mysql_*` methods. ADR 0010's k54 amendment calls `_verify_pid` "a
  fourth `PoolBase` override next to the three ADR 0003 names", which was the
  count on its date.
