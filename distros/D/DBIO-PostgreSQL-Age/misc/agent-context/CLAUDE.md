# CLAUDE.md — DBIO::PostgreSQL::AGE

The family skills, agents and house rules are not stored in this repo: they are installed from
the shared sources by skilletor (`.claude/skilletor.json`) and git-ignored. A fresh clone or
worktree has them — `.claude/rules/.local.dbio-rules.md`, `.claude/agents/.local.*`, the
`dbio-*` skills — only after `skilletor sync` (needs the `skilletor@getty` plugin and network
access to the sources); run it first, and again before `dzil build`. Never edit an installed
copy; change the source. This repo tracks only its own `skilletor.json` and the skill
`dbio-postgresql-age`. The family-wide house rules (discipline, delegation, release) live in
`.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main agent and all
subagents.

## Delegation

Delegate behavior-relevant driver internals (AGE graph-extension wiring, Storage, types) to
this repo's `dbio-worker-postgresql-age` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-postgresql-age` (default), `dbio-release-manager`,
`karr-coordinator`.

## Workspace Overview

This is a DBIO driver distribution for PostgreSQL with the Apache AGE graph extension.

## Distribution Configuration

Uses `[@DBIO]` plugin bundle from `Dist::Zilla::PluginBundle::DBIO`.

## Testing

Offline tests use `DBIO::Test->init_schema(no_deploy => 1)` (mock storage); `t/00-load.t` also runs the `DBIO::Test::StorageLayer` contract. They touch no database and are the default:

```bash
../dbio/maint/capped-test prove -lr t/
```

Every suite — offline and live — runs through `capped-test` (house rule 9) and recursively (`-r`).

Live tests need PostgreSQL with the Apache AGE extension and run when the `DBIO_TEST_PG_*` variables are set; without them the live files skip:

```bash
export DBIO_TEST_PG_DSN="dbi:Pg:dbname=<your-database>"
export DBIO_TEST_PG_USER=<user>
export DBIO_TEST_PG_PASS=<password>
../dbio/maint/capped-test prove -lr t/
```

Use a database of this repo's own, never one that another repo's suite works in. How databases are provided, capped and shared is in the live-testing section of `.claude/rules/.local.dbio-rules.md`; no pods, port-forwards or `docker run` are described here.

## Deploy

AGE graphs are created per graph (`create_graph`), and `t/11-age-deploy.t` only loads fixtures via `create_graph` plus idempotent `MERGE`. Schema deploy (test-deploy-and-compare) lives in DBIO::PostgreSQL. This distribution adds only what AGE needs to coexist with it: `DBIO::PostgreSQL::Age::Extension` is the extension class of the declared list (core ADR 0066; `__PACKAGE__->pg_extensions('age')`, loading the component does not declare it). The driver runs it inside deploy: its `inspect` reads `ag_catalog.ag_graph` into the model, its `claims` name the schema of every graph, so graph schemas are known to the model and never dropped (ADR 0004; ADR 0005 is superseded). Deploy stays with the driver storage — the AGE storage layer defines no `dbio_deploy_class`; `DBIO::PostgreSQL::Age::Deploy` and `::Introspect` are stubs that only keep the names loadable. `pg_schemas` stays possible on top. AGE beside PostGIS commutes by the protocol (disjoint rule sets), checked by `t/50-extension-set.t`.
