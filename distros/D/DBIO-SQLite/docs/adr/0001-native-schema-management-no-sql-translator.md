# 1. Native schema management, no SQL::Translator

Date: 2026-06-20

## Status

Accepted

## Context

DBIx::Class -- the upstream baseline this driver forks -- performs schema
deployment and DDL generation through SQL::Translator (SQLT): `deploy()`,
`deployment_statements()`, `create_ddl_dir()`, and the
`SQL::Translator::Parser::DBIx::Class` / `Producer::SQLite` pair. SQLT is a
large, generic, slow translation layer that has to model every engine it
supports through one abstract schema object.

DBIO replaced this whole path with per-driver native classes. For SQLite the
relevant modules are `DBIO::SQLite::DDL` (desired-state DDL from Result
classes), `DBIO::SQLite::Introspect` (live state via `sqlite_master` +
PRAGMA), `DBIO::SQLite::Diff` (model-to-model comparison), and
`DBIO::SQLite::Deploy` (install/diff/apply/upgrade orchestration on top of
`DBIO::Deploy::Base`). SQLite has no schemas, sequences, functions, triggers
or RLS, so its native DDL surface is small and a generic translator buys
nothing here.

This is structurally the fork's first decision for the driver: it is recorded
in the initial commit (`add9e7a`) and the `Changes` entry ("native deploy,
introspect, diff and DDL generation -- no SQL::Translator").

## Decision

The SQLite driver owns its full schema-management pipeline natively and does
not depend on SQL::Translator. The four native classes are the single source
of truth for DDL generation, introspection, diffing and deployment.

The legacy SQLT-driven tests carried over from DBIx::Class
(`t/86sqlt.t`, `t/99dbic_sqlt_parser.t`) are gated with
`BEGIN { plan skip_all => ... }` and kept as skip-with-reason markers rather
than deleted, so the removed contract stays visible.

## Consequences

- DDL output is plain, one-statement-at-a-time SQL tailored to SQLite, with
  only `CREATE TABLE`, `CREATE INDEX` and `CREATE VIEW` emitted.
- No SQLT runtime or build dependency; faster, with no generic abstraction to
  fight.
- The legacy `deployment_statements()` contract no longer generates SQL on the
  fly. Core's `DBIO::Storage::DBI::deployment_statements()` now only reads a
  pre-existing DDL file or throws (this contract change is core-owned). The
  SQLite driver routes deployment through `dbio_deploy_class` ->
  `DBIO::SQLite::Deploy` instead.
- Each new SQLite-specific DDL feature must be implemented in the native
  classes -- there is no generic producer to fall back on.

## Related

- ADR 0002 (in-memory test-deploy-and-compare upgrades)
- ADR 0003 (column ALTER via whole-table rebuild)
- DBIO core "clean break with DBIx::Class -- no runtime compat shim" (core
  ADR 0001 / core commit `70cbeb81`) -- the family-wide policy this driver
  implements; that decision is owned by core, not recorded here.
