# ADR 0007 — The future_io async transport drives the DSN's own DBD binding

- Status: accepted; the mechanism (split by class) superseded 2026-10-04 by a
  choice per connection (karr k60), see the addendum. The decision stands.
- Date: 2026-07-08
- Tags: async, future_io, drivers, mariadb, storage, dbd

## Addendum (2026-10-04, karr k60) — the binding is chosen per connection, by its DBD

The decision stands: the async adapter drives whichever DBD the DSN named.
What does not hold is the mechanism chosen for it, the split by class. The
Decision bullets that place the DBD::mysql binding in
`DBIO::MySQL::Storage::Async` and the DBD::MariaDB binding in
`DBIO::MySQL::Storage::MariaDB::Async`, the third Rationale paragraph ("Keying
the split on the base/subclass storage classes") and the first and last
Consequences bullets are superseded by this addendum. They are left as written,
as history.

**What the rationale missed.** It assumed that "the DBD is decided once, at
storage-class resolution", so that `dbi:mysql:` always means
`DBIO::MySQL::Storage` and `dbi:MariaDB:` always means
`DBIO::MySQL::Storage::MariaDB`. That holds only for a schema that loads no
driver component and lets the DSN pick the class. A schema component pins the
storage class for **every** DSN: `DBIO::MySQL::connection` sets
`+DBIO::MySQL::Storage`, `DBIO::MySQL::MariaDB::connection` sets
`+DBIO::MySQL::Storage::MariaDB`, and `DBIO::MySQL::Storage` has no `_rebless`.
So `load_components('MySQL')` over a `dbi:MariaDB:` DSN resolves
`DBIO::MySQL::Storage::Async` and runs it on DBD::MariaDB handles. The pool
connect asked for `mysql_auto_reconnect` and died with "Unknown attribute
mysql_auto_reconnect" (live, 2026-09-26, MySQL 8.0.30, DBD::MariaDB 1.24), and
behind it every primitive was DBD::mysql's. The mirror image,
`load_components('MySQL::MariaDB')` over `dbi:mysql:`, was wrong the other way
round. The class and the DBD are two independent choices; the user makes the
second one with the DSN, which is what this ADR set out to honour.

A second thing the rationale could not see: with an AccessBroker the DSN is the
broker's answer for one connection, asked again for the next. It is not a
property of the storage object at all, so no choice made per class or per
storage can be right for it.

**Decision.** The six DBD-specific primitives of `DBIO::MySQL::Storage::Async`
(`_async_prepare_attrs`, `_conn_socket_fd`, `_async_ready`, `_async_result`,
`_async_insertid`, `_mysql_auto_reconnect_attr`) answer for the DBD of the
connection in hand:

- Before the connect there is no handle. `_mysql_connect`, the one
  `DBI->connect` of the transport (pool and listen connection), names the
  auto-reconnect attribute through `_mysql_auto_reconnect_attr($dsn)`, which
  reads the DBD off the DSN this connection is opened with, as DBI and core's
  `_extract_driver_from_connect_info` do: the driver part of `dbi:DRIVER:`, or
  `DBI_DRIVER` when the DSN names none.
- From then on the DBD is the handle's `$dbh->{Driver}{Name}`. `_mysql_binding`
  reads it once, before the connection's first statement, and keeps it on the
  connection. The five async primitives take the connection, not a bare handle.
- The names come from the one table in `DBIO::MySQL::Storage`
  (`_dbd_attribute`), which k59 introduced for the sync storage and which now
  also carries the async binding (`async`, `socket_fd`, `async_ready`,
  `async_result`). A DBD it has no names for is refused, before the connect,
  naming the DBD.
- `DBIO::MySQL::Storage::MariaDB::Async` stays, empty: it is the name the
  future_io convention resolves for `DBIO::MySQL::Storage::MariaDB`.

No `@ISA` changed, no component pins a different class, and the convention
resolver is untouched. Which transport class a connection gets is as before;
it no longer matters for the DBD.

**Why this mechanism.** It follows the precedent of karr k59 (ADR 0005
addendum, commit 4753945), which moved the sync storage from "by class" to "by
the DBD on the handle" for the same reason, and is the younger and tested of
the two patterns in this dist. The rationale above rejected "a runtime
`if $dbh->{Driver}{Name} eq 'mysql'` branch" in favour of the class split; what
replaces the split is a table lookup, not a branch, but it is a runtime choice
and that rejection is hereby reversed. The alternative, making the class follow
the DSN (a `_rebless`, or a component that does not pin), is a change to the
composition seam and to which class a component pins, was ruled out of k60's
scope, and would still not serve a broker whose DSN changes per connection.
**The choice of mechanics was made by the coordinating agent under house rule
5 and is still to be read by the maintainer.**

**Consequences.**

- A new DBD-specific async concern is a new key in the `_dbd_attribute` table
  and a primitive that looks it up for its connection. An override of a
  primitive in a transport subclass keyed on a DBD is the old mistake.
- A future MySQL-protocol DBD is one more row in that table, not an `::Async`
  partner class overriding the primitives.
- Test fakes that hand the transport a connection must say which DBD they play
  in `{Driver}{Name}`, as a DBI handle does (`t/59`, `t/60`, `t/62`).
- The statements this supersedes elsewhere: ADR 0001 ("Only the async
  primitives remain per class"), the "Still open" paragraph of the k59
  addendum to ADR 0005, and ADR 0008's "overridden in
  `DBIO::MySQL::Storage::MariaDB::Async`".

**Tests.** `t/66-future-io-dbd-per-connection.t`, offline, with one strict
fake per DBD: component x DSN in all four combinations for the pool connection,
a statement on it and the listen connection; a Vault broker with a
`dbi:MariaDB:` DSN under `load_components('MySQL')`; one transport whose broker
changes DBD between two connections held at once; refusal of an unknown DBD.
Against the pre-k60 code it fails 25 of 88, the first with the error the card
was filed for. `t/54` section 4b asserted the class binding and now asserts its
absence.

**Live-verified 2026-10-05.** `t/75-future-io-component-dbd-live.t` runs both
components over both DBDs against a real server: the pool connection and a
statement on it, the insertid of an INSERT checked against the table, the
listen connection and a delivered notify, each on a handle of the DSN's DBD.
Green in all eight cells of component x DBD (DBD::mysql 4.055, DBD::MariaDB
1.24) x server (MySQL 8.0.30, MariaDB 11.8.8). Against the lib before this
change it fails in exactly the two cells where component and DSN disagree:
`MySQL` over `dbi:MariaDB:` with the error the card was filed for,
`MySQL::MariaDB` over `dbi:mysql:` at the first `mariadb_sockfd` call. The
broker cases of `t/66` are not repeated live there.

## Context

ADR 0001 established that this one distribution serves both MySQL and MariaDB:
`DBIO::MySQL::Storage` is the base (the `mysql` DBD name, `DBD::mysql`, `mysql_*`
attributes) and `DBIO::MySQL::Storage::MariaDB` is a thin subclass overriding
only the DBD divergences (`mariadb_*`, `mariadb_insertid`, ...). Both register in
the core driver registry from the same dist, so `dbi:mysql:` and `dbi:MariaDB:`
DSNs auto-detect into their respective storage class. ADR 0001 also recorded, as
a consequence, that the async path lived in a *separate* distribution — a
consequence since superseded by ADR 0030, which brought async into this dist as
convention-resolved per-connection modes (`{ async => 'future_io' }` resolves
`ref($storage) . '::Async'`).

When the future_io async adapter (`DBIO::MySQL::Storage::Async`, karr #18) first
landed, it was built entirely on DBD::MariaDB's `mariadb_async` binding —
`mariadb_sockfd`, `mariadb_async_ready`, `mariadb_async_result`,
`mariadb_insertid` — with `DBIO::MySQL::Storage::MariaDB::Async` an empty thin
subclass. But the base async class is the convention target of
`DBIO::MySQL::Storage`, i.e. the **`dbi:mysql:` / DBD::mysql** path. So a
`dbi:mysql:` connection asking for future_io resolved the base adapter and then
called `mariadb_sockfd` on a DBD::mysql handle — a method that does not exist
there. Async was, silently, MariaDB-only, even though the DSN and the sync layer
said the user had chosen DBD::mysql.

Both DBDs expose the same async model — a single async query per connection plus
a socket fd for the event loop — and differ only in the attribute/method names,
the exact `mysql_*` vs `mariadb_*` prefix divergence ADR 0001 already lists for
the sync layer:

    DBD::mysql    async         mysql_fd       mysql_async_ready   mysql_async_result   mysql_insertid
    DBD::MariaDB  mariadb_async mariadb_sockfd mariadb_async_ready mariadb_async_result mariadb_insertid

## Decision

Mirror the ADR 0001 sync DBD split in the async transport: the async adapter
drives whichever DBD the DSN named.

- Factor the five DBD-specific operations into named primitive methods on the
  base async class: `_async_prepare_attrs`, `_conn_socket_fd`, `_async_ready`,
  `_async_result`, `_async_insertid`. These are the *only* places a DBD's async
  binding is named.
- `DBIO::MySQL::Storage::Async` (base, the `dbi:mysql:` convention target)
  carries the **DBD::mysql** binding in those primitives: `{ async => 1 }`,
  `mysql_fd`, `mysql_async_ready`, `mysql_async_result`,
  `$sth->{mysql_insertid}`.
- `DBIO::MySQL::Storage::MariaDB::Async` (the `dbi:MariaDB:` convention target)
  overrides only those five primitives with the **DBD::MariaDB** `mariadb_*`
  binding — it is no longer an empty subclass.
- The shared transport control flow stays DBD-agnostic in the base and calls the
  primitives: the `_submit_query` / `_collect_result` await-and-collect loop,
  connection pooling, the txn seams, SQL shaping, and the last-insert-id →
  returned-columns mapping.
- Neither DBD is loaded at compile time (`use DBD::MariaDB` was dropped from the
  base); `DBI->connect` pulls the one the DSN names.

This is the precise async analogue of the sync `_dbh_last_insert_id` override
from ADR 0001 (`mysql_insertid` on the base, `mariadb_insertid` on the MariaDB
subclass).

## Rationale

The two DBDs are two drivers that happen to share a distribution (ADR 0001); the
async transport is a driver behaviour, so it must follow the DBD the user
selected via the DSN, exactly as the sync path does. Anything else silently
ignores the user's `dbi:mysql:` choice.

The primitive-factoring keeps the divergence to five one-line methods and the
shared async control flow in exactly one place — the same "isolate each
divergence to a single named override" discipline ADR 0001 uses for the sync
layer. Duplicating the whole `_submit_query` / `_collect_result` flow per DBD
would have been the wrong unit of reuse (the argument ADR 0001 makes against a
second distribution, one level down).

Keying the split on the base/subclass storage classes — not a runtime
`if $dbh->{Driver}{Name} eq 'mysql'` branch — reuses the convention resolver
already in place: `dbi:mysql:` → `DBIO::MySQL::Storage` → `::Storage::Async`;
`dbi:MariaDB:` → `::Storage::MariaDB` → `::Storage::MariaDB::Async`. The DBD is
decided once, at storage-class resolution, and the async class is simply its
partner.

## Consequences

- A new DBD-specific async concern is one override in the MariaDB subclass,
  mirroring the sync rule: adding a `mariadb_*` call to the base is a smell — it
  belongs in a primitive the subclass overrides.
- `DBD::MariaDB` stays optional to a DBD::mysql user (ADR 0001): the base async
  class no longer `use`s it, so a `dbi:mysql:` future_io install needs only
  DBD::mysql (plus dbio-async). The cpanfile keeps `recommends DBD::MariaDB` /
  `suggests DBD::mysql`, and DBIO::Async a `recommends` (karr #27).
- The DBD::mysql (`mysql_*`) async path is implemented to the DBD::mysql
  documentation and covered offline (t/54 asserts the per-DBD primitives). When
  this was written it was not live-verified: DBD::mysql 5.x does not build
  against a libmariadb-only client (karr k21). It is since 2026-10-05, with
  DBD::mysql 4.055 against MySQL 8.0.30 and MariaDB 11.8.8 (t/55, t/63, t/75).
  The DBD::MariaDB (`mariadb_*`) path is live-verified (t/55).
- ADR 0001's consequence "the async path lives in a separate distribution" is
  historical — superseded by ADR 0030 (async is in-dist, mode-registry-resolved)
  and refined here: the in-dist async transport now honours the DBD split too.
- A future MySQL-protocol engine added as a `::Storage` subclass (ADR 0001) that
  wants async provides its own `::Async` partner overriding the primitives for
  its DBD binding; the shared control flow is inherited.
