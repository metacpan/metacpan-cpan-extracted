# CLAUDE.md — DBIO::SQLite

The family skills, the shared agents (`dbio-adr-auditor`, `dbio-release-manager`,
`karr-coordinator`) and the house rules (discipline, delegation, release) come from the
`dbio` core repo through skilletor and are git-ignored, so a fresh clone does not have them
yet: install the `skilletor@getty` plugin, then run `skilletor sync` in the repo root (it
needs network access to the sources in `.claude/skilletor.json`). Only then do
`.claude/rules/.local.dbio-rules.md` (auto-loaded by Claude Code for the main agent and all
subagents), `dbio-worker-sqlite` and the family skills exist. Never edit an installed copy;
change the source in core and sync again. This repo tracks only its own: `skilletor.json`
and the `dbio-sqlite*` skills.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, types) to this repo's
`dbio-worker-sqlite` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-sqlite` (default), `dbio-adr-auditor`,
`dbio-release-manager`, `karr-coordinator`.

## Namespace

- `DBIO::SQLite` -- SQLite schema component
- `DBIO::SQLite::Storage` -- SQLite storage

## Usage

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('SQLite');
```

## Tests

SQLite runs in the test process, so the whole suite is offline: no server, no `DBIO_TEST_*`
DSN, no live run. `t/` has about twenty subdirectories, and `prove -l t/` is not recursive:
it skips them and reports green. Run every suite through the cap wrapper from core (house
rule 9), recursively, never with `prove -j`:

```
../dbio/maint/capped-test prove -lr t/       # or: ../dbio/maint/capped-test dzil test
```

The test database is `:memory:`; `DBIO_TEST_SQLITE_USE_FILE=1` uses a temp file instead.
