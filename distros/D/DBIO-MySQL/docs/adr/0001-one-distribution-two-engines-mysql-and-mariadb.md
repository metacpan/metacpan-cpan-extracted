# ADR 0001 — One distribution serves both MySQL and MariaDB

- Status: accepted
- Date: 2026-06-20
- Tags: drivers, mariadb, registry, storage, backfill

## Context

DBIx::Class shipped MySQL and MariaDB support as two storage classes inside
the monolith — `DBIx::Class::Storage::DBI::mysql` and
`DBIx::Class::Storage::DBI::MariaDB` — driven by the `mysql` and `MariaDB`
DBD names (`DBD::mysql` vs `DBD::MariaDB`). The DBIO fork splits every engine
into its own driver distribution (core ADR 0001 / 0006). That raised a
question this dist had to answer and never wrote down: are MySQL and MariaDB
*one* DBIO driver distribution or two?

The two engines share almost everything — wire dialect, `information_schema`
introspection, backtick quoting, `LIMIT off, rows` pagination, the
self-referencing DML rewrite. They diverge in a handful of places: the DBD
attribute prefix (`mysql_*` vs `mariadb_*`), the last-insert-id handle key
(`mysql_insertid` vs `mariadb_insertid`), `FOR SHARE` vs `LOCK IN SHARE MODE`
locking syntax, and the `SHOW SLAVE STATUS` → `SHOW REPLICA STATUS` rename.

## Decision

Ship **one** distribution, `DBIO-MySQL`, that serves both engines. MariaDB is
modelled as a thin subclass layer, not a sibling distribution.

- MySQL is the base: `DBIO::MySQL` (schema component) → `DBIO::MySQL::Storage`
  → `DBIO::MySQL::SQLMaker`.
- MariaDB is a subclass triple that overrides only the deltas:
  `DBIO::MySQL::MariaDB` (component) → `DBIO::MySQL::Storage::MariaDB`
  (`use base 'DBIO::MySQL::Storage'`) → `DBIO::MySQL::SQLMaker::MariaDB`
  (`use base 'DBIO::MySQL::SQLMaker'`).
- Both register in the core driver registry from the **same** distribution:
  `DBIO::MySQL::Storage` registers the `mysql` DBD name, and
  `DBIO::MySQL::Storage::MariaDB` registers the `MariaDB` DBD name
  (`Storage/MariaDB.pm`, `DBIO::Storage::DBI->register_driver('MariaDB' => ...)`).
  So `dbi:mysql:` and `dbi:MariaDB:` DSNs both auto-detect into this dist.
- Users opt into MariaDB explicitly by loading the MariaDB component
  (`load_components('MySQL::MariaDB')`), which pins
  `+DBIO::MySQL::Storage::MariaDB` as the storage type.
- The MariaDB subclasses carry *only* the deltas:
  `_dbh_last_insert_id` (`mariadb_insertid`), `_run_connection_actions`
  (disable `mariadb_auto_reconnect`), `_replication_status_row`
  (`SHOW REPLICA STATUS` first), and the `share` → `LOCK IN SHARE MODE`
  mapping in the MariaDB SQLMaker.

  **Update (2026-08-05, karr #30): the last two are superseded.** The subclass
  is the `DBD::MariaDB` binding, not the MariaDB *server*: DBD::MariaDB reaches
  MySQL servers and `dbi:mysql:` reaches MariaDB ones, so an SQL-dialect delta
  placed here answers for the wrong engine in two of the four combinations.
  Only the DBD deltas remain (`_dbh_last_insert_id`,
  `_run_connection_actions`, the async primitives). The replica-status verb and
  the locking-read grammar are now decided in `DBIO::MySQL::Storage` from
  `_is_mariadb` plus the server version — see the amendments to ADR 0003 and
  ADR 0004, and karr #28 for the first delta that moved (the upsert row alias).

  **Update (2026-09-26, karr k59): the sync DBD deltas left too.** The class
  does not tell you the DBD either. `load_components('MySQL')` pins
  `DBIO::MySQL::Storage` over a `dbi:MariaDB:` DSN, so a `mariadb_*` name bound
  to the subclass never reaches that DBD::MariaDB handle. `_dbh_last_insert_id`
  and `_run_connection_actions` now live in `DBIO::MySQL::Storage` only, and
  both name the attribute by the DBD on the handle (see the k59 addendum to
  ADR 0005). Only the async primitives remain per class (ADR 0007).

  **Update (2026-10-04, karr k60): the async primitives left too.** They are
  chosen per connection, by its DBD (ADR 0007 addendum). No DBD delta is bound
  to a class any more.

## Rationale

The engines are one dialect with a thin compatibility skin, not two
databases. A second distribution would duplicate the entire MySQL Storage /
SQLMaker / Introspect / DDL / Diff / Deploy stack to override four methods —
the wrong unit of reuse. Subclassing keeps the shared surface in exactly one
place and isolates each divergence to a single named override that documents
what MariaDB does differently. The dual `register_driver` calls mean DSN
auto-detection works for both engines without the user picking a distribution;
the component split (`MySQL` vs `MySQL::MariaDB`) only matters when the user
wants the MariaDB-specific behaviour forced regardless of the DBD in the DSN.

This is the same shape the fork uses elsewhere for a base engine plus a
near-clone variant, and it is why there is no `DBIO-MariaDB` on CPAN.

## Consequences

- New cross-engine behaviour goes in `DBIO::MySQL::*`; only a genuine MySQL/
  MariaDB divergence earns an override in the `::MariaDB` subclass. Adding an
  override to the base that MariaDB must *not* inherit is a smell — check the
  subclass.
- The `DBD::MariaDB` dependency is optional from MySQL's point of view: a
  MySQL-only user never loads the MariaDB component and never needs it. The
  cpanfile must keep the MariaDB DBD a `suggests`/test-only concern, not a hard
  MySQL runtime `requires`.
- The async path lives in a **separate** distribution, `DBIO-MySQL-Async`
  (`DBIO::MySQL::Async`, EV::MariaDB) — that is a different protocol/base
  (`DBIO::Storage::Async`, Futures), not a third subclass here. The
  blocking/async split is owned there, not by this ADR.
  **Update (2026-07-08): this consequence is superseded.** Async is no longer a
  separate distribution. ADR 0030 brought it in-dist as convention-resolved
  per-connection modes (`{ async => 'ev' | 'future_io' }`): the `future_io`
  transport base ships in `dbio-async`, the `ev` mode in the optional
  `dbio-mysql-ev` dist. ADR 0007 then applies *this* ADR's DBD split to the
  future_io transport — the base `DBIO::MySQL::Storage::Async` carries the
  DBD::mysql binding and `DBIO::MySQL::Storage::MariaDB::Async` overrides the
  `mariadb_*` primitives, exactly like the sync split above.
- Future engines that are MySQL-protocol-compatible (e.g. a Percona/TiDB-style
  fork) should be evaluated as another `::Storage` subclass + registry entry
  in this dist before a new distribution is considered.
