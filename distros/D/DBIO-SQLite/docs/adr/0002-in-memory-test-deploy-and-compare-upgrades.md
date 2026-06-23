# 2. In-memory test-deploy-and-compare for upgrade diffing

Date: 2026-06-20

## Status

Accepted

## Context

Upgrading a deployed schema needs a diff between the live database and the
desired schema. There are two broad strategies:

1. Compute the diff from abstract class representations (what SQLT-era tooling
   attempted, and what is lossy because the in-class model and the on-disk
   model rarely agree byte-for-byte).
2. Deploy the desired schema to a throwaway database, introspect it, and diff
   two *introspected* models that were produced by the same code path.

DBIO drivers use strategy 2. The PostgreSQL driver realises the throwaway
target as a temporary database (Postgres has no in-process database). SQLite
has `:memory:`, an in-process database that exists only for the life of a
connection -- so the throwaway target can be far cheaper and simpler than the
PostgreSQL temp-database variant.

The shared orchestration (`install`, `diff`, `apply`, `upgrade`) lives in
`DBIO::Deploy::Base`; only the engine-specific target-model build is the
driver's concern (`DBIO::Deploy::Base` hooks `_ddl_class`, `_introspect_class`,
`_diff_class`, `_build_target_model`). This split, and the SQLite adoption of
the base, are recorded in karr #3.

## Decision

`DBIO::SQLite::Deploy::_build_target_model` builds the diff target by:

1. connecting to a fresh `dbi:SQLite::memory:` database,
2. enabling `PRAGMA foreign_keys = ON`,
3. deploying the desired-state DDL (`DBIO::SQLite::DDL`) into it,
4. introspecting that in-memory database with `DBIO::SQLite::Introspect`,
5. disconnecting (the target DB then vanishes).

The live database is introspected through the same `DBIO::SQLite::Introspect`
code path, so source and target models are directly comparable by
`DBIO::SQLite::Diff`. The in-memory connection is dropped explicitly before
the diff object is built, for predictable lifetime.

## Consequences

- Both sides of the diff come from one introspection implementation, so the
  comparison cannot drift between "how we describe the schema in classes" and
  "how SQLite actually stored it".
- The target is in-process and ephemeral -- no temp file, no cleanup, no
  second real database. This is the deliberate divergence from the PostgreSQL
  driver's temp-database approach.
- `_build_target_model` is the only SQLite-specific piece of the deploy
  orchestration; the rest is inherited from `DBIO::Deploy::Base`.
- A target model built this way carries each table's original `CREATE TABLE`
  text (captured from `sqlite_master`), which ADR 0003 relies on for faithful
  table rebuilds.

## Related

- ADR 0001 (native schema management)
- ADR 0003 (column ALTER via whole-table rebuild)
- karr #3 (adoption of `DBIO::Deploy::Base` / `Diff::Op` / introspect defaults)
