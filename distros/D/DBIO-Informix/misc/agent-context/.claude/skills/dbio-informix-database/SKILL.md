---
name: dbio-informix-database
description: Use when you need IBM Informix IDS specifics for driver work — DBD::Informix, SQL dialect, coltype mapping, SERIAL, transactions, SKIP/FIRST paging, sys* catalog.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

IBM Informix (IDS) for Perl DB driver development. Database counterpart to the
`dbio-informix` driver skill. Where this conflicts with generic Informix lore,
trust the driver code.

## DBD::Informix

Requires the IDS server or ESQL/C client libraries (Informix CSDK) installed,
plus `$INFORMIXDIR`/`$INFORMIXSERVER` in the environment. Synchronous only — no
async path. Connection:
```perl
DBI->connect("dbi:Informix:database\@server", $user, $pass)
$schema->connect("dbi:Informix:myapp")   # database[@server]; "database=myapp" is SQL -354
```
The autoincrement value lands in the statement handle's `ix_sqlerrd[1]`
attribute after an INSERT — the driver reads it there for `last_insert_id`.

## Version Notes

IDS = Informix Dynamic Server (the modern engine; v11/12/14). Catalog layout
(`sys*` tables) is stable across these. SQLite/DuckDB-style `:memory:` does
not exist — the deploy path creates a throwaway database `WITH LOG`, deploys
into it, introspects it and drops it.

## Type System

Driver type vocabulary lives in `DBIO::Informix::Types` (`coltype % 256` →
logical name; logical → DDL string).

| Logical | Informix SQL | coltype |
|---------|--------------|---------|
| char / nchar | CHAR(n) | 0 / 15 |
| smallint | SMALLINT | 1 |
| integer | INTEGER | 2 |
| float | DOUBLE PRECISION | 3 |
| smallfloat | REAL | 4 |
| decimal / money | DECIMAL(p,s) / MONEY | 5 / 8 |
| serial / serial8 / bigserial | SERIAL / SERIAL8 / BIGSERIAL | 6 / 18 / 53 |
| date | DATE | 7 |
| datetime | DATETIME y TO fraction(5) | 10 |
| interval | INTERVAL | 14 |
| bytea | BYTE | 11 |
| text | TEXT | 12 |
| varchar / nvarchar | VARCHAR(n) | 13 / 16 |
| int8 / bigint | INT8 / BIGINT | 17 / 52 |
| set / multiset / list | collections | 19 / 20 / 21 |
| lvarchar | LVARCHAR | 40 |
| blob / clob / boolean | opaque, told apart by `extended_id` 10 / 11 / 5 | 41 |
| boolean | BOOLEAN | 45 |

`coltype` is taken modulo 256. The table is `%LOGICAL_FOR_COLTYPE` in
`DBIO::Informix::Types`; `logical_for_coltype` is the authority.

Sized DDL types default to `(255)` when no size given.

## Identity (SERIAL)

`SERIAL` (INT4), `SERIAL8` (INT8), `BIGSERIAL` (INT8) are *types*, not column
attributes — never combine with a base type and never emit a DEFAULT. Driver
maps `is_auto_increment` → bare `SERIAL`. New value retrieved per-INSERT from
`$sth->{ix_sqlerrd}[1]`, not a separate `LAST_INSERT_ID()` call.

## Transactions & Locking

Only **logged** databases support transactions/savepoints; **unlogged** DBs
(created without WITH LOG) silently ignore COMMIT/ROLLBACK. Savepoints:
`SAVEPOINT name` / `ROLLBACK TO SAVEPOINT name` — **cannot be released**
(driver's `_exec_svp_release` is a no-op). Deferred FKs:
`SET CONSTRAINTS ALL DEFERRED` ... `SET CONSTRAINTS ALL IMMEDIATE`, wrapped in
a transaction (`with_deferred_fk_checks`). No `SELECT ... FOR UPDATE` — the
SQLMaker disables `_lock_select`.

## Pagination

`SkipFirst` limit dialect — Informix puts the clause right after `SELECT`:
```sql
SELECT SKIP ? FIRST ? me.id, me.col FROM t me ...   -- offset, count
SELECT FIRST ? ...                                  -- count only, no offset
```
Not a trailing `LIMIT/OFFSET`. `FIRST n` alone for no-offset queries.

## Identifier Quoting & Case

Driver quotes with `"` (`sql_quote_char('"')`). Informix reads a double-quoted
token as an identifier only when `DELIMIDENT` is set at connect time; the
driver sets `DELIMIDENT=y` itself in `_connect`, and without it every quoted
statement is a -201 syntax error. Catalog `tabname`/`colname` come back
lowercase.

## Unicode / Charset

No connection-level `SET NAMES`. Locale is environment-driven: `DB_LOCALE` /
`CLIENT_LOCALE` (e.g. `en_US.utf8`); `GL_USEGLU=1` enables ICU/Unicode
collation. `NCHAR`/`NVARCHAR` use the database locale collation. Datetime
formatting is set via `connect_call_datetime_setup`: `GL_DATETIME="%Y-%m-%d
%H:%M:%S.%F5"`. The client reads `DBDATE`/`DBCENTURY`/`GL_DATE` when it
connects, so `_connect` pins `DBDATE=MDY4/` for the connect and restores the
caller's values (`t/31-date-client-env.t`).

## Introspection Catalog

System catalog is the lowercase `sys*` tables under owner `informix`:

| Table | Use |
|-------|-----|
| `systables` | tables/views (`tabtype` T/V), owner, `tabid` |
| `syscolumns` | columns: `coltype`, `collength`, `colno` |
| `sysdefaults` | column default values (`type` C/T = current/today) |
| `sysindexes` | index `part1..part16` column slots |
| `sysconstraints` | constraints, `constrtype` P (pk) / R (fk) |
| `sysreferences` | FK targets, `match`/`upd_rule`/`del_rule` |

Catalog queries filter out system owners (`informix`, `sys`, `sysmaster`, ...).

## Testing Env Vars

`DBIO_TEST_INFORMIX_DSN`, `DBIO_TEST_INFORMIX_USER`, `DBIO_TEST_INFORMIX_PASS`
(gate live tests; skipped when unset). Test server: image
`icr.io/informix/informix-developer-database:latest`, manifest
`maint/k8s/informix.yaml`. Every suite, live or offline, runs through
`maint/capped-test` (and a live one after `maint/live-preflight`); the rules are in
`dbio-driver-development`, `references/live-testing.md`.
