# ADR 0002 — Temp-DATABASE deploy (not temp-schema): separate database + AutoCommit dance + schema filter

- Status: accepted
- Date: 2026-06-20
- Tags: deploy, temp-database, autocommit, multi-tenant, drivers

## Context

Core's test-and-compare migration (core ADR 0007) needs to deploy the desired
schema into a throwaway location, introspect it, and diff it against the live
database. Core ADR 0006 makes deploy a native, per-driver concern, and core
ships `DBIO::Deploy::Base::TempDatabase` as the shared orchestration for engines
that need a real scratch database: create temp db → deploy + introspect →
always drop. PostgreSQL is exactly such an engine — but two PostgreSQL realities
do not fit the generic temp-database flow:

1. `CREATE DATABASE` / `DROP DATABASE` **cannot run inside a transaction
   block**, and DBD::Pg connections default to a transaction being open.
2. This driver manages a *subset* of namespaces (`pg_schemas`), so
   introspection of the scratch database must be scoped to those namespaces or
   it would diff against `public` and the catalog noise.

A temp-*schema* approach (create a scratch namespace in the live database
instead of a whole database) was rejected: it cannot reproduce database-level
objects (extensions, settings) and risks colliding with or mutating live state.

## Decision

`DBIO::PostgreSQL::Deploy` extends core's `DBIO::Deploy::Base::TempDatabase`
(`Deploy.pm:7`) — inheriting `install` / `diff` / `apply` / `upgrade` unchanged
— and overrides only the genuinely PostgreSQL-specific seams. This is the
PostgreSQL specialisation of the strategy owned by core ADR 0006 (native deploy)
and core ADR 0007 (test-and-compare); see those for the strategy itself.

- **Real separate database, with the AutoCommit dance.** `_create_temp_db`
  commits any open transaction and locally forces `AutoCommit => 1` around
  `CREATE DATABASE`, because it cannot run in a txn; `_drop_temp_db` is
  symmetric around `DROP DATABASE IF EXISTS` (`Deploy.pm:121-144`). The temp
  database name is `temp_db_prefix . $$ . '_' . time()`.
- **Schema filter from `pg_schemas` into introspection.** The introspector
  factory `_new_introspect` reads the connected schema's `pg_schemas` and passes
  them as `schema_filter` so introspection of both live and temp databases stays
  scoped to the managed namespaces (`Deploy.pm:101-109`). The core base only
  passes `dbh`.
- **`install_schema` is kept, PostgreSQL-only.** `CREATE SCHEMA IF NOT EXISTS`
  for one namespace (`Deploy.pm:79-84`) — the per-schema install primitive that
  multi-tenant setups loop over to give each tenant its own namespace. It has no
  counterpart in the flat-namespace drivers.

## Rationale

PostgreSQL comparing with itself is always correct (core ADR 0007's premise), so
the scratch target must be a faithful PostgreSQL database, not a same-database
namespace that cannot hold extensions or settings. The AutoCommit dance is not
optional polish: without committing and dropping into autocommit, `CREATE
DATABASE` raises *"CREATE DATABASE cannot run inside a transaction block"* under
DBD::Pg's default open transaction. The `schema_filter` exists because this
driver is namespace-scoped by design (ADR 0001) — introspecting unmanaged
namespaces would produce spurious diffs.

karr #4 SEAM D records exactly this split: adopt `TempDatabase`, delete the
inherited `install`/`apply`/`upgrade`/`diff`/`_dbh`/`temp_db_prefix`, but
**keep** `_create_temp_db`/`_drop_temp_db` (the AutoCommit dance), `install_schema`
(pg-only), and the `_new_introspect` override that forwards `schema_filter`.

## Consequences

- A migration needs CREATEDB privilege and a server that allows `CREATE
  DATABASE` (no open txn at that moment). On a connection pool that keeps a txn
  open, the forced `COMMIT` in `_create_temp_db`/`_drop_temp_db` is load-bearing.
- The temp database is always dropped (core `TempDatabase` guarantees the drop
  and re-raises on failure), so a failed diff never leaks a scratch database.
- Multi-tenant install is a supported first-class path via `install_schema`,
  distinct from full `install`. This stays in the driver, not core, because no
  flat-namespace engine has the concept.
- If core ever moves the AutoCommit-around-DDL handling into `TempDatabase`
  itself, these two overrides become candidates for removal — until then they
  must stay even though the rest of the orchestration is inherited.
