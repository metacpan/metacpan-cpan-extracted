---
name: dbio-informix-database
description: Use when you need IBM Informix IDS specifics for driver work — DBD module, SQL dialect, types, SERIAL, transactions, pagination.
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
DBIO::Schema->connect("dbi:Informix:dbname=myapp")   # driver style
```
The autoincrement value lands in the statement handle's `ix_sqlerrd[1]`
attribute after an INSERT — the driver reads it there for `last_insert_id`.

## Version Notes

IDS = Informix Dynamic Server (the modern engine; v11/12/14). Catalog layout
(`sys*` tables) is stable across these. SQLite/DuckDB-style `:memory:` does
not exist — the deploy path introspects a live throwaway schema instead.

## Type System

Driver type vocabulary lives in `DBIO::Informix::Types` (`coltype % 256` →
logical name; logical → DDL string).

| Logical | Informix SQL | coltype |
|---------|--------------|---------|
| smallint | SMALLINT | 2 |
| integer | INTEGER | 3 |
| bigint | BIGINT | 17 / 52 |
| serial | SERIAL | 6 |
| float | (DOUBLE PRECISION) | 5 |
| smallfloat | REAL | 18 |
| decimal | DECIMAL(s) | 14 |
| char / nchar | CHAR(n) | 0,1 / 15 |
| varchar / nvarchar | VARCHAR(n) | 13 / 16 |
| lvarchar | LVARCHAR | 40 |
| text | TEXT | 12 |
| bytea | BYTE | 11 |
| date | DATE | 7 |
| datetime | DATETIME y TO fraction(5) | 8,9,10 |
| blob/clob, set/multiset/list | smart/collection LOBs | 41, 19-21 |

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

Driver quotes with `"` (`sql_quote_char('"')`). Double-quoted identifiers are
literal/case-sensitive only when `DELIMIDENT` is set in the environment;
without it Informix folds unquoted names to lowercase and treats `"x"` as a
string literal in some contexts. Catalog `tabname`/`colname` come back
lowercase.

## Unicode / Charset

No connection-level `SET NAMES`. Locale is environment-driven: `DB_LOCALE` /
`CLIENT_LOCALE` (e.g. `en_US.utf8`); `GL_USEGLU=1` enables ICU/Unicode
collation. `NCHAR`/`NVARCHAR` use the database locale collation. Datetime
formatting is set via `connect_call_datetime_setup`: `GL_DATETIME=%Y-%m-%d
%H:%M:%S%F5` (takes effect), `GL_DATE` (often ignored mid-process); `DBDATE`
and `DBCENTURY` are cleared.

## Introspection Catalog

System catalog is the lowercase `sys*` tables under owner `informix` (NOT
DB2-style `SYSCAT`):

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
(gate live tests; skipped when unset). Docker: `ibmcom/informix-developer` /
`icr.io/informix/informix-developer-database`.
