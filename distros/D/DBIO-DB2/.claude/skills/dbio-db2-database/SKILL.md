---
name: dbio-db2-database
description: Use when you need IBM Db2 LUW specifics for driver work — DBD module, SQL dialect, types, identity, transactions, pagination.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

IBM Db2 (LUW) for Perl DB driver development.

## DBD module + DSN

`DBD::DB2` (driver name `DB2`). Connection:
```perl
DBI->connect("dbi:DB2:SAMPLE", $user, $pass)         # cataloged database alias
DBI->connect("dbi:DB2:DATABASE=mydb;HOSTNAME=h;PORT=50000;PROTOCOL=TCPIP", $user, $pass)
```
Needs the IBM Data Server Driver / DB2 client libraries installed. The driver
registers via `__PACKAGE__->register_driver('DB2' => ...)` in `DBIO::DB2::Storage`.

## Edition / version notes

LUW (Linux/Unix/Windows) is the target. Pagination does not depend on the server
version: `DBIO::DB2::SQLMaker::apply_limit` branches on whether the query has an
offset — `ROW_NUMBER() OVER()` with one, `FETCH FIRST` without (ADR 0003).
Default port 50000 (TCPIP). `sysibm.sysdummy1` is the one-row dual-equivalent.

## Type system

Driver maps DBIO types to Db2 types (`DBIO::DB2::Type::_db2_column_type`):

| DBIO type | Db2 type |
|-----------|----------|
| tinyint/smallint | SMALLINT |
| boolean/bool | BOOLEAN |
| int/integer/serial | INTEGER |
| bigint/bigserial | BIGINT |
| real | REAL |
| float | FLOAT |
| double / double precision | DOUBLE PRECISION |
| numeric/decimal | DECIMAL |
| text (with size) / varchar / json | VARCHAR(n) |
| text (no size) | CLOB |
| char | CHAR |
| clob | CLOB |
| blob | BLOB |
| binary | BINARY(n), VARBINARY(n) above 255 |
| varbinary | VARBINARY(n) |
| date/time | DATE/TIME |
| datetime/timestamp/timestamptz | TIMESTAMP |
| interval / enum / bit | refused: `DBIO::Exception` |
| uuid | CHAR(16) |

Only json collapses (to VARCHAR). interval, enum and bit have no Db2 type; the
mapping throws `DBIO::Exception` before the server is asked.

Sizes: `varchar`/`varbinary`/`json` without a size throw (Db2 refuses them with
SQL0604N; no length is guessed). `text` without a size is a `CLOB`. Types written
without a length (`SMALLINT`, `INTEGER`, `BIGINT`, `REAL`, `DOUBLE PRECISION`,
`DATE`, `TIME`, `XML`, `BOOLEAN`) drop any size that comes with the column; the
catalog reports a LENGTH for every one of them. `binary` takes up to 255 bytes,
above that it is written `VARBINARY(n)`; above 32672 the mapping throws (use a
blob).
Datetime parsing: `DateTime::Format::DB2` (`datetime_parser_type`).

## Identity / auto-increment

Db2 uses identity columns, not sequences-by-default. DDL emits:
```sql
col INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)
```
Last insert id retrieval (`_dbh_last_insert_id`):
```sql
SELECT IDENTITY_VAL_LOCAL() FROM sysibm.sysdummy1
```
`IDENTITY_VAL_LOCAL()` is connection-scoped (last identity assigned on this
connection). Introspection detects identity via `SYSCAT.COLUMNS.IDENTITY = 'Y'`.

## Transactions / locking / savepoints

Db2 is transactional (ACID). `COMMIT` / `ROLLBACK`. Db2 LUW runs DDL inside the
unit of work, yet the storage declares `_use_transactional_ddl(0)`: the compare
deploy runs on the storage's own handle (only a schema can be thrown away, not
a database), so a transactional upgrade would pull the whole compare deploy into
the migration's unit of work. DDL runs statement by statement with AutoCommit on;
re-running `upgrade` recomputes the diff against live state (reasoning in
`DBIO::DB2::Storage` and `DBIO::DB2::Deploy`). Locking is row/table level; isolation levels CS
(cursor stability, default), RR, RS, UR. `SELECT ... FOR UPDATE` / `WITH RR`.

## Pagination

`DBIO::DB2::SQLMaker::apply_limit` picks the form by offset presence:

```sql
-- no offset (FETCH FIRST, _FetchFirst):
SELECT ... FETCH FIRST 10 ROWS ONLY

-- with offset (ROW_NUMBER, _RowNumberOver):
SELECT * FROM (
  SELECT inner.*, ROW_NUMBER() OVER (...) AS rno FROM (...) inner
) WHERE rno BETWEEN offset+1 AND offset+rows
```
`FETCH FIRST` cannot express an offset, so the offset form uses
`ROW_NUMBER() OVER()` (ADR 0003).

## Identifier quoting + case folding

Quote char is `"` (`sql_quote_char('"')`). Name separator is queried from the
server via `SQL_QUALIFIER_NAME_SEPARATOR` (default `.`). Db2 folds unquoted
identifiers to UPPERCASE; quoted identifiers are case-sensitive. Catalog tables
(`SYSCAT.*`) store names uppercased — introspection matches on uppercase names.

## Unicode / charset

Database created with `CODESET UTF-8`. Db2 distinguishes byte length vs char
length for VARCHAR/CHAR — `CODEUNITS32`/`OCTETS` qualifiers exist for explicit
character semantics. The driver does not set a charset flag; create the DB UTF-8.

## Introspection catalog

Reads system catalog views under the `SYSCAT` schema (`DBIO::DB2::Introspect`,
default schema `USER`):

| Source view | Used for |
|-------------|----------|
| `SYSCAT.TABLES` | tables + views (`kind`) |
| `SYSCAT.COLUMNS` | columns, identity (`IDENTITY='Y'`) |
| `SYSCAT.INDEXES` | indexes (`UNIQUERULE`: P=pk, U=unique, D=dup) |
| `SYSCAT.INDEXCOLUSE` | index columns |
| `SYSCAT.TABCONST` | constraints (`TYPE` F=FK, P=PK, U=unique; ADR 0009) |
| `SYSCAT.KEYCOLUSE` | key columns (FK + PK) |
| `SYSCAT.REFERENCES` | FK parent table, `DELETERULE`/`UPDATERULE` |

FK parent columns are resolved by re-querying the parent PK (`TYPE='P'`).

## FK handling

Db2 enforces referential integrity. New tables get inline FK in CREATE TABLE;
existing tables use ALTER TABLE. DDL topo-sorts tables so parents precede
children. `DELETERULE`/`UPDATERULE` map to `on_delete`/`on_update`.

## Testing env vars

`DBIO_TEST_DB2_DSN`, `DBIO_TEST_DB2_USER`, `DBIO_TEST_DB2_PASS`; the values come
from `dbio-db env db2` (core skill `dbio-driver-development`,
`references/live-testing.md`). Live tests skip unless DSN and USER are set
(`t/10-db2.t` tests `$dsn && $user`); `t/10-db2.t` is also gated on the
`test_rdbms_db2` optional-dependency group. Offline and live suites both run
through `../dbio/maint/capped-test prove -lr t/`; before a live run
`../dbio/maint/live-preflight`. Docker: `ibmcom/db2` /
`icr.io/db2_community/db2` (needs license acceptance + privileged container).
