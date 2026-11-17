# CLAUDE.md — DBIO::MySQL

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main
agent and all subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-mysql` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-mysql` (default), `dbio-release-manager`,
`dbio-adr-auditor`, `karr-coordinator`.

## Namespace

- `DBIO::MySQL` — MySQL schema component
- `DBIO::MySQL::MariaDB` — MariaDB schema component
- `DBIO::MySQL::Storage` — MySQL storage
- `DBIO::MySQL::Storage::MariaDB` — MariaDB storage

## Usage

```perl
# MySQL
package MyApp::DB;
use DBIO Schema => -mysql;      # same as use base 'DBIO::Schema' + load_components('MySQL')

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

Error text without values: t/178-t/181; masker `DBIO::MySQL::Util::mask_error_details`.

The server words its errors in the language of the session (`lc_messages`), so the masking
hangs on the error code (`$dbh->err`, the optional 4th argument), not on the wording: a code
that quotes a value says where the value sits, and a text that does not have that structure
is withheld, only the code stays. The hook `_mask_error_values($text, \@values, $statement)`
keeps its signature. A test that reads the English wording of a server message sets
`SET SESSION lc_messages = 'en_US'` itself.

## Live suite in another server language

`DBIO_TEST_SERVER_LANGUAGE=de` (or `fr`) makes every connection of the live suite report in
that language (`SET SESSION lc_messages`, never `SET GLOBAL`); unset or empty leaves the
server's default. `.proverc` runs each test file through `perl -Ilib -It/lib
-MDBIOMySQLTestLanguage`, which wraps `DBI->connect` and `DBI->connect_cached`: after a
connection to a mysql or MariaDB driver handle succeeds, the wrapper sets the session language.
The DSN is not rewritten. A test that reads the English wording of a server text sets
`lc_messages = 'en_US'` in its own `on_connect_do`, which runs after the wrapper (t/182). It
applies to `prove` run from the root of the distribution (`DBIO_TEST_SERVER_LANGUAGE=de prove -lr t/`).
`make test`, `dzil test` and `perl t/x.t` do not read `.proverc`: with the switch set, t/01 fails
there (the hook is not loaded) instead of letting an English run pass for a German one. A single
file: `perl -Ilib -It/lib -MDBIOMySQLTestLanguage t/<file>.t`.
