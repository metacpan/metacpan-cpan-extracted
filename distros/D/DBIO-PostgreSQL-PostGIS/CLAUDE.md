# CLAUDE.md — DBIO::PostgreSQL::PostGIS

The family skills, agents and the house rules (`.claude/rules/.local.dbio-rules.md`) are not
tracked here: they come from the `dbio` core repo through skilletor and exist only after
`skilletor sync` — run it first in a fresh clone or worktree (needs the `skilletor@getty`
plugin and network access to the sources in `.claude/skilletor.json`). Never edit an
installed copy; change the source in core. Once synced, the house rules (discipline,
delegation, release) are auto-loaded by Claude Code for the main agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (PostGIS spatial-extension wiring, Storage,
types) to this repo's `dbio-worker-postgresql-postgis` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-postgresql-postgis` (default), `dbio-release-manager`,
`karr-coordinator`.

## Workspace Overview

This is a DBIO driver distribution for PostgreSQL with the PostGIS spatial extension.

## Distribution Configuration

Uses `[@DBIO]` plugin bundle from `Dist::Zilla::PluginBundle::DBIO`.

## Extension

PostGIS is declared by the schema (`pg_extensions('postgis')`, ADR 0066), not by loading a
component or choosing a storage type; the driver runs the declared list. The extension class
`DBIO::PostgreSQL::PostGIS::Extension` carries the model rules (geometry type and SRID of a
column, `ST_Transform` on an SRID change, refusal of a type change), names the storage layer
and the inflation component. `postgis_topology` has its own `Topology::Extension`. Deploy
stays with the driver (ADR 0064) — this distribution defines no `dbio_deploy_class`; its
`::Deploy` and `::Introspect` classes are stubs. The extension never determines the driver
(ADR 0067; see the house rules).

## Testing

Offline tests use `DBIO::Test::Storage` (mock storage) and need no database. Always run
recursively and through the capped wrapper (house rule 9):

```bash
../dbio/maint/capped-test prove -lr t/
```

Live tests need PostgreSQL with the PostGIS extension. This repo's database is `dbio_postgis`;
the suite reads `DBIO_TEST_PG_DSN` / `DBIO_TEST_PG_USER` / `DBIO_TEST_PG_PASS` (or
`DBIO_TEST_PG_EXT_*` for pg-ext). Without them the live tests skip. How to bring a database up
and what the live-run rules are: house rules, *Live testing — resource discipline*. Never
`prove -j`, and never against another repo's database.

```bash
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/
```
