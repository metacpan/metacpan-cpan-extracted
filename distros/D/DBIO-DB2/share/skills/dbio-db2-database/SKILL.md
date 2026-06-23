---
name: dbio-db2-database
description: "IBM Db2 (LUW) knowledge for Perl driver development (DBD module, SQL dialect, types, identity, transactions, pagination)"
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

LUW (Linux/Unix/Windows) is the target. Pagination branches on version:
DB2 5.4+ supports `ROW_NUMBER() OVER()`; older versions only `FETCH FIRST`.
Default port 50000 (TCPIP). `sysibm.sysdummy1` is the one-row dual-equivalent.

## Type system

Driver maps DBIO types to Db2 types (`DBIO::DB2::Type::_db2_column_type`):

| DBIO type | Db2 type |
|-----------|----------|
| tinyint/smallint/boolean/bool | SMALLINT |
| int/integer/serial | INTEGER |
| bigint/bigserial | BIGINT |
| real | REAL |
| float | FLOAT |
| double / double precision | DOUBLE PRECISION |
| numeric/decimal | DECIMAL |
| text/varchar/json | VARCHAR |
| char | CHAR |
| clob | CLOB |
| blob/binary | BLOB |
| varbinary | VARBINARY |
| date/time | DATE/TIME |
| datetime/timestamp/timestamptz | TIMESTAMP |
| interval | INTERVAL |
| uuid | CHAR(16) |

No native BOOLEAN or JSON in the mapping — both collapse (SMALLINT, VARCHAR).
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

Db2 is transactional (ACID). `COMMIT` / `ROLLBACK`. Savepoints:
`SAVEPOINT sp ON ROLLBACK RETAIN CURSORS` / `ROLLBACK TO SAVEPOINT sp` /
`RELEASE SAVEPOINT sp`. Locking is row/table level; isolation levels CS
(cursor stability, default), RR, RS, UR. `SELECT ... FOR UPDATE` / `WITH RR`.

## Pagination

`DBIO::DB2::SQLMaker::apply_limit` picks the form by offset presence:

```sql
-- no offset (FETCH FIRST, _FetchFirst):
SELECT ... FETCH FIRST 10 ROWS ONLY

-- with offset (ROW_NUMBER, _RowNumberOver, DB2 5.4+):
SELECT * FROM (
  SELECT inner.*, ROW_NUMBER() OVER (...) AS rno FROM (...) inner
) WHERE rno BETWEEN offset+1 AND offset+rows
```
Modern Db2 also supports `OFFSET n ROWS FETCH FIRST m ROWS ONLY`, but the
driver uses `ROW_NUMBER()` for offset for broad compatibility.

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
| `SYSCAT.TABCONST` | constraints (`TYPE` F=FK, P=PK) |
| `SYSCAT.KEYCOLUSE` | key columns (FK + PK) |
| `SYSCAT.REFERENCES` | FK parent table, `DELETERULE`/`UPDATERULE` |

FK parent columns are resolved by re-querying the parent PK (`TYPE='P'`).

## FK handling

Db2 enforces referential integrity. New tables get inline FK in CREATE TABLE;
existing tables use ALTER TABLE. DDL topo-sorts tables so parents precede
children. `DELETERULE`/`UPDATERULE` map to `on_delete`/`on_update`.

## Testing env vars

`DBIO_TEST_DB2_DSN`, `DBIO_TEST_DB2_USER`, `DBIO_TEST_DB2_PASS`.
Tests skip unless DSN and USER are set (`t/10-db2.t`); also gated on the
`test_rdbms_db2` optional-dependency group. Docker: `ibmcom/db2` /
`icr.io/db2_community/db2` (needs license acceptance + privileged container).
