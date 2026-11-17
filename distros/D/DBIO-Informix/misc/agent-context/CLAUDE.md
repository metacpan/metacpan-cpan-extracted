# CLAUDE.md — DBIO::Informix

This distribution tracks only its own files (`.claude/skilletor.json`, the `dbio-informix*`
skills and the settings); the family skills, the shared agents and the house rules come from
core through skilletor, and everything named here refers to those. The family-wide house rules
(discipline, delegation, release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by
Claude Code for the main agent and all subagents.

## Fresh clone — run `skilletor sync` first

The family skills, the shared agents (`dbio-adr-auditor`, `dbio-release-manager`,
`karr-coordinator`), the worker `dbio-worker-informix` and the house rules
(`.claude/rules/.local.dbio-rules.md`) are installed and untracked, so a fresh clone or
worktree has none of them until `skilletor sync` has run (ADR 0058 in core). It needs the
`skilletor` plugin or CLI and network access to the sources in `.claude/skilletor.json`.
Run it before relying on a briefing and before `dzil build`. Never edit an installed copy:
change the source in core, then sync again.

## Live testing

The driver runs against Informix 15: `maint/k8s/informix.yaml` is the throwaway test pod
(`dbio-db up informix` starts it), `DBD::Informix` is built against the Informix Client SDK
(CSDK 15, `$INFORMIXDIR` set), and `maint/upstream/` holds the CSDK 15 patch for
`DBD::Informix` with the build recipe. Every suite runs through `maint/capped-test`
(house rules, *Live testing*).

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-informix` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-informix` (default), `dbio-release-manager`,
`karr-coordinator`, `dbio-adr-auditor`.

## Namespace

- `DBIO::Informix` — Informix schema component (`use DBIO Schema => -ix`)
- `DBIO::Informix::Storage` — Informix storage (inherits `DBIO::Storage::DBI`)
- `DBIO::Informix::SQLMaker` — Informix SQL generation
- `DBIO::Informix::{DDL,Deploy,Introspect,Diff,Types,ColumnDef,Util}` — schema mgmt, test-and-compare, type vocabulary

## Usage

```perl
package MyApp::DB;
use DBIO Schema => -ix;

my $schema = MyApp::DB->connect('dbi:Informix:myapp');   # dbi:Informix:database[@server]
```

## Design notes

- **Built on DBD::Informix** (requires IDS or ESA client). No XS compile.
- **Auto-increment** is `SERIAL`; the new value is `$sth->{ix_sqlerrd}[1]` (`last_insert_id`).
- **`DELIMIDENT=y`** is set by the driver in `_connect`.
- **Introspection** reads the lowercase `sys*` catalog (`systables`, `syscolumns`, `sysindexes`, `sysconstraints`, `sysreferences`).
- **Deploy** uses test-deploy-and-compare: introspect live, deploy desired into throwaway DB, introspect that, diff.
- **DATE format**: `_connect` pins `DBDATE=MDY4/` (hiding `DBCENTURY`, `GL_DATE`) for the connect, where the client reads them; `GL_DATETIME` is set via `connect_call_datetime_setup`.
- **`SELECT ... FOR UPDATE`** is not supported — SQLMaker disables it.
- **Identifier quoting** is `"` (same as PostgreSQL/SQLite).

## Introspection

`DBIO::Informix::Introspect` extends `DBIO::Introspect::Base` (lazy `_build_model`):

Model shape mirrors the standard DBIO introspector shape:

```perl
{
    tables       => { $name => { ... } },
    columns      => { $table => [ { name => 'id', data_type => 'INTEGER', ... }, ... ] },
    indexes      => { $table => { $name => { ... } } },
    foreign_keys => { $table => [ { ... }, ... ] },
    unique_constraints => { $table => [ { ... }, ... ] },
}
```

## Diff

`DBIO::Informix::Diff` extends `DBIO::Diff::Base` (lazy `_build_operations`); per-entity `Diff::{Table,Column,Index,ForeignKey,PrimaryKey,UniqueConstraint}`.

## Deploy

`DBIO::Informix::Deploy` uses test-deploy-and-compare in a throwaway
database (`DBIO::Deploy::Base::TempDatabase`, like dbio-mysql). Informix has no
`:memory:` mode, so `diff` creates a database `WITH LOG` (on a connection to no database:
`CREATE DATABASE` is refused on a connection to a database, -759), deploys the
plain install DDL there on a second connection, introspects it and drops it
(`CLOSE DATABASE`, then `DROP DATABASE`) in every case — comparing the live
model against the freshly-deployed one. The live DSN must be
`dbi:Informix:database[@server]`.

## DDL

`DBIO::Informix::DDL` generates CREATE statements.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/
```

Tests assume DBD::Informix and Informix client libraries are present; live tests read `DBIO_TEST_INFORMIX_DSN/_USER/_PASS`. Run suites through `maint/capped-test` (see *Live testing*).

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::Informix` | Schema component |
| `DBIO::Informix::Storage` | DBI storage, `ix_sqlerrd` auto-increment |
| `DBIO::Informix::SQLMaker` | SQL generation (no FOR UPDATE) |
| `DBIO::Informix::Deploy` | test-deploy-and-compare orchestrator |
| `DBIO::Informix::Diff` | Compare introspected models |
| `DBIO::Informix::Introspect` | Read live DB via the `sys*` catalog |
| `DBIO::Informix::DDL` | Generate CREATE statements |
| `DBIO::Informix::Introspect::Tables/Columns/Indexes/ForeignKeys/UniqueConstraints` | Per-entity introspection |
| `DBIO::Informix::Diff::Table/Column/Index/ForeignKey/PrimaryKey/UniqueConstraint` | Per-entity diff |