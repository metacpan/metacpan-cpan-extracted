# CLAUDE.md — DBIO::MySQL

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main
agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-mysql` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-mysql` (default), `dbio-release-manager`,
`karr-coordinator`.

## Namespace

- `DBIO::MySQL` — MySQL schema component
- `DBIO::MySQL::MariaDB` — MariaDB schema component
- `DBIO::MySQL::Storage` — MySQL storage
- `DBIO::MySQL::Storage::MariaDB` — MariaDB storage

## Usage

```perl
# MySQL
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL');

# MariaDB
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL::MariaDB');
```

## utf8mb4 on connect: attribute hash, not DSN

DBD::mysql (4.055) honours `mysql_enable_utf8mb4` only in the attribute hash of the
connect info; in the DSN it is ignored silently and strings come back as bytes.
DBD::MariaDB (1.24) has no such attribute and refuses the connect with `Unknown
attribute` — leave it out there. See the POD of `DBIO::MySQL::Storage`.

## MariaDB: FULLTEXT after a diff

A FULLTEXT index that `upgrade` drops and creates again does not find the rows written
while the old index existed on MariaDB (server behaviour, MySQL is unaffected). The diff does
not rebuild; the way out is `ALTER TABLE ... FORCE` on the table. See the POD of
`DBIO::MySQL::Diff::Index`.

## Error text without values

Error text without values: t/179, t/180; masker `DBIO::MySQL::Util::mask_error_details`.
