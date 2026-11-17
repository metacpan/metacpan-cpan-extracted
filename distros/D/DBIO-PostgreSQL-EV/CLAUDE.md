# CLAUDE.md — DBIO::PostgreSQL::EV

The skills, agents and the shared `.claude/rules/` named here come from core and are
installed by skilletor; this distribution tracks only its own (`.claude/skilletor.json`, the
`dbio-postgresql-ev` skill). On a fresh clone or worktree run `skilletor sync` first (plugin
`skilletor@getty`, network to the sources) — until then the house rules
(`.claude/rules/.local.dbio-rules.md`), the agents and the family skills do not exist. Never
edit an installed copy; change the source in core. The house rules (discipline, delegation,
release) are auto-loaded by Claude Code for the main agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (async Storage, Pool, LISTEN/NOTIFY, types) to
this repo's `dbio-worker-postgresql-ev` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-postgresql-ev` (default), `dbio-release-manager`,
`karr-coordinator`.

## Overview

Async PostgreSQL storage for DBIO using EV::Pg. Bypasses DBI entirely —
speaks libpq's async protocol directly for maximum performance.

## Namespace

- `DBIO::PostgreSQL::EV` — the dist's name-giving main module: distribution overview POD (no methods, no `connection()` hook)
- `DBIO::PostgreSQL::EV::Storage` — Async storage implementation (extends DBIO::Storage::Async)
- `DBIO::PostgreSQL::EV::Pool` — EV::Pg connection pool

## Key Architecture

- Uses EV::Pg (libpq XS wrapper), NOT DBI/DBD::Pg
- Users connect with a `dbi:Pg:` DSN plus `{ async => 'ev' }`; libpq conninfo is
  the transport-internal shape (`ConnectInfo::dbi_to_conninfo` translates)
- Returns Future.pm objects from all async methods
- Sync methods (select, insert, etc.) work by blocking via ->get
- Pipeline mode for batching queries in single round-trip
- LISTEN/NOTIFY via dedicated connection

## Dependencies

- EV::Pg >= 0.09, no upper bound (fork safety in a child, error_fields cleared on
  a lost connection, no misdelivery to a nested loop in a callback; still
  references libpq 16 symbols, so libpq 15 needs `maint/docker/`)
- Future >= 0.49
- DBIO core

## Testing

- `t/00-load.t` — loads every module, plus the ADR 0032 §7 storage-layer contract for
  `DBIO::PostgreSQL::EV` (that one check skips without `DBIO::Test::StorageLayer`)
- `t/01-storage-api.t` — offline API surface of the storage (`future_class`, the method
  list) and the SQL maker's quoted SQL; never skips
- `t/02-access-broker.t` — AccessBroker unit tests (no real DB)
- `t/10-integration.t` — EV::Pg live tests; requires `DBIO_TEST_PG_DSN` + EV::Pg
- `t/11-access-broker-live.t` — AccessBroker live tests with real PG; requires `DBIO_TEST_PG_DSN` + EV::Pg,
  and a test user that may create roles (it logs in as roles of its own; skips otherwise)
- `t/119-error-values-live.t` — no bound value in the text of any server error, on every EV path
  and on `future_io`; requires `DBIO_TEST_PG_DSN` + EV::Pg (`future_io` part skips without
  IO::Async/DBIO::Async)
- `t/120-error-values-mock.t` — the same offline: no `error_fields`, session reset, connect action
- `t/122-error-values-language-live.t` — no bound value in a server error under `lc_messages` de_DE.UTF-8
  and fr_FR.UTF-8, on every EV path (skips a language the server has no locale for)

### Server message language

`DBIO_TEST_SERVER_LANGUAGE=de|fr` runs the live suite against a server that reports in German or
French (`t/lib/LiveServer.pm` puts `-c lc_messages=...` into `PGOPTIONS`; an unknown value ends the
file at once). A test that reads the server's English wording sets `lc_messages = 'C'` in its own
session; it does not skip.

### Running the suites

Every run goes through core's `capped-test` (house rule 9); never `prove -j`.

```bash
# offline (no database)
env -u DBIO_TEST_PG_DSN ../dbio/maint/capped-test prove -lr t/

# live: DBIO_TEST_PG_DSN / _USER / _PASS, in a database of this repo's own (dbio_pgev)
../dbio/maint/capped-test prove -lr t/
```

The maintainer's own database is `dbio_pgev`; its login comes from `dbio-db env postgresql`.
Where the live server comes from, and the one-run-per-database rule, is in the house rules
(*Live testing*, *Maintainer-only live infrastructure*). On the shared PostgreSQL this repo
works in `dbio_pgev`, never in `dbio_test`.
