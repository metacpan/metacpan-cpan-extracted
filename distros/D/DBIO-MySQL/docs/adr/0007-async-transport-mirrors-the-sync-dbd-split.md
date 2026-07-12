# ADR 0007 — The future_io async transport drives the DSN's own DBD binding

- Status: accepted
- Date: 2026-07-08
- Tags: async, future_io, drivers, mariadb, storage, dbd

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
  documentation and covered offline (t/54 asserts the per-DBD primitives), but is
  not yet live-verified: DBD::mysql 5.x does not build against a libmariadb-only
  client. Live verification with a `dbi:mysql:` DSN is tracked as karr
  dbio-mysql #21. The DBD::MariaDB (`mariadb_*`) path is live-verified (t/55).
- ADR 0001's consequence "the async path lives in a separate distribution" is
  historical — superseded by ADR 0030 (async is in-dist, mode-registry-resolved)
  and refined here: the in-dist async transport now honours the DBD split too.
- A future MySQL-protocol engine added as a `::Storage` subclass (ADR 0001) that
  wants async provides its own `::Async` partner overriding the primitives for
  its DBD binding; the shared control flow is inherited.
