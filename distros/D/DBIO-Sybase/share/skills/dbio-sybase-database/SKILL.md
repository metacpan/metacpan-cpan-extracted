---
name: dbio-sybase-database
description: "Sybase ASE / SAP ASE knowledge for Perl driver development (DBD::Sybase/FreeTDS, SQL dialect, types, IDENTITY, transactions, pagination)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Sybase ASE (Adaptive Server Enterprise, now SAP ASE) for Perl DB driver development.
This is the database counterpart to the `dbio-sybase` driver skill — facts here are
grounded in the live `DBIO::Sybase` driver code. **Trust the driver over generic
Sybase knowledge when they conflict.**

## DBD::Sybase + FreeTDS

`DBD::Sybase` is the only DBI driver. It can be compiled against either the native
Sybase OpenClient libraries (full functionality) or **FreeTDS** (experimental).
Connection:
```perl
DBI->connect("dbi:Sybase:server=myserver;database=mydb", $user, $pass)
```
FreeTDS detection: `$dbh->{syb_oc_version} =~ /freetds/i`. The driver mixes in
`DBIO::Sybase::Storage::FreeTDS` automatically when FreeTDS is detected.

| Concern | OpenClient | FreeTDS |
|---------|-----------|---------|
| TEXT/IMAGE columns | works | **do not work** |
| `$dbh->{LongReadLen}` | works | unavailable → `SET TEXTSIZE n` (default 32768) |
| Transactions | `syb_chained_txn`=1 (`SET CHAINED`) | explicit `BEGIN TRAN`/`COMMIT`/`ROLLBACK` |
| Statement caching | works | disabled for FreeTDS > 0.82 (buggy) |
| `maxConnect` DSN | patched to 256 to avoid exhaustion | same |

## ASE Version Notes

If the server lacks placeholder support the storage reblesses to
`...::ASE::NoBindVars`; typeless placeholders trigger `auto_cast(1)`. Server type is
probed at first use via `sp_server_info @attribute_id=1` (`SQL_Server` → `ASE`).

## Type System

Driver type mapping (`DBIO::Sybase::DDL::sybase_column_type`, logical → ASE):
integer/bigint → `INT`; smallint/tinyint → `SMALLINT`; serial/bigserial → `BIGINT`;
varchar/nvarchar → `VARCHAR(255)`; char/nchar → `CHAR(1)`; text/long/clob → `TEXT`;
date/timestamp/datetime → `DATETIME`; smalldatetime → `SMALLDATETIME`;
bytea/blob → `IMAGE`; numeric/decimal → `NUMERIC(18,6)`; float/real → `FLOAT`;
double precision → `DOUBLE PRECISION`; boolean → `BIT`.

- **money** — ASE-native fixed-point currency type (also `smallmoney`).
- **text/image** — LOB types; written on a dedicated writer connection
  (`_writer_storage`), separate from the main insert. Set `syb_binary_images = 1`
  (via `connect_call_blob_setup`) to get raw binary instead of hex.
- **datetime / smalldatetime** — `SMALLDATETIME` has only minute precision.
  Driver sets `syb_date_fmt('ISO_strict')` for output and `SET DATEFORMAT mdy`
  for input. Custom format class parses `%Y-%m-%dT%H:%M:%S.%3NZ`, formats
  `%m/%d/%Y %H:%M:%S.%3N`.

## Identity (autoincrement)

ASE uses an **`IDENTITY`** column attribute (emitted as `... IDENTITY` in DDL),
not a sequence. There is no `SCOPE_IDENTITY()` equivalent.

- Default retrieval: `SELECT MAX(col) FROM table` inside a locked transaction on
  the writer connection (the "dumb last_insert_id hack").
- `@@IDENTITY` is the connection-global alternative; when `_identity_method` is
  `'@@IDENTITY'` the `SELECT MAX` hack is skipped.
- Inserting an explicit identity value requires `SET IDENTITY_INSERT` (via
  `DBIO::Storage::DBI::IdentityInsert`); updating one requires identity-update flags.
- Identity columns are detected in introspection from `syscolumns.status & 128`
  (bit `0x80`) — INFORMATION_SCHEMA does not expose this.
- `INSERT ... DEFAULT VALUES` is unsupported; the driver emits explicit `DEFAULT`
  per column instead (skipping identity, timestamp, computed columns).

## Transactions / Chained Mode / Locking

- **Chained mode** is ASE's autocommit-off mode: `SET CHAINED ON/OFF`. Non-FreeTDS
  sets `$dbh->{syb_chained_txn} = 1`; FreeTDS uses explicit `BEGIN TRAN`.
- Savepoints use ASE syntax: `SAVE TRANSACTION name` / `ROLLBACK TRANSACTION name`.
  Re-issuing `SAVE TRANSACTION` with the same name releases the prior one (release
  is a no-op).
- `CREATE DATABASE` / `DROP DATABASE` cannot run inside a transaction — Deploy
  forces `AutoCommit = 1` for those.
- Page/row locking is server- and table-config dependent (allpages vs datarows).

## Pagination — NO native LIMIT/OFFSET

ASE has **no** `LIMIT`/`OFFSET`. The driver implements limit-only via:
```sql
SET ROWCOUNT 10
SELECT ...
SET ROWCOUNT 0
```
This only applies when there is a limit **and no offset** (`_prep_for_execute`).
There is no native `OFFSET`; offset pagination must be emulated (`ROW_NUMBER()`
windowing on newer ASE, or client-side skip). ASE also supports `TOP n`, but the
driver uses `SET ROWCOUNT`.

## Identifier Quoting + Case Sensitivity

Quote char is **square brackets**: `sql_quote_char([qw/[ ]/])` → `[col]`. Case
sensitivity of identifiers and string comparisons is **server-dependent** (set by
the server's sort order / charset at install time); do not assume.

## Unicode

ASE Unicode types: `unichar` / `univarchar` / `unitext` (UTF-16). The server's
default charset (e.g. `iso_1`, `utf8`) governs `char`/`varchar`. Configure charset
on the connection rather than assuming UTF-8.

## Introspection Catalog

Driver reads mostly via `INFORMATION_SCHEMA` views (TABLES, COLUMNS,
KEY_COLUMN_USAGE, TABLE_CONSTRAINTS, REFERENTIAL_CONSTRAINTS, STATISTICS), with one
drop to the native system catalog for identity detection:
`syscolumns` JOIN `sysobjects` (type `'U'`) JOIN `sysusers`, testing
`c.status & 128`. Other native catalog tables: `sysobjects`, `sysindexes`.
FKs are readable and emitted in DDL (`ON DELETE`/`ON UPDATE` rules). Unique
constraints are emitted as `CREATE UNIQUE INDEX`, not inline constraints; ASE does
not support `CHECK` constraints the way other engines do.

## Testing Env Vars

`DBIO_TEST_SYBASE_DSN` (used by the test suite). `DBIO_TEST_SYBASE_USER` /
`DBIO_TEST_SYBASE_PASS` by convention. `DBIO_SYBASE_FREETDS_NOWARN=1` silences the
FreeTDS-support warning. ASE has no `:memory:` DB — Deploy creates a temp database
`CREATE DATABASE <prefix><pid>_<time>` and drops it after compare.
