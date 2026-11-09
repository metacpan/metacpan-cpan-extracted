---
name: dbio-sybase-database
description: Use when you need Sybase ASE or SAP ASE specifics for driver work — DBD::Sybase and FreeTDS, dialect, types, IDENTITY, transactions, pagination.
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
| TEXT/IMAGE columns | works | content **cannot be written** (no `ct_send_data`); `undef` (NULL) and `''` (stored as one space / `0x20`) go through |
| `$dbh->{LongReadLen}` | works | unavailable → `SET TEXTSIZE n` (default 32768) |
| Transactions | `syb_chained_txn`=1 (`SET CHAINED`) | explicit `BEGIN TRAN`/`COMMIT`/`ROLLBACK` |
| Statement caching | works | disabled for FreeTDS <= 0.82 (buggy); newer FreeTDS keeps it |
| `maxConnect` DSN | patched to 256 to avoid exhaustion | same |

## ASE Version Notes

If the server lacks placeholder support the storage reblesses to
`...::ASE::NoBindVars` (which always disables statement caching); placeholders
without typeless-placeholder support trigger `auto_cast(1)`. Server type is
probed at first use via `sp_server_info @attribute_id=1` (`SQL_Server` → `ASE`).

## Type System

Driver type mapping (`DBIO::Sybase::DDL::sybase_column_type`, logical → ASE):
integer/serial → `INT`; bigint/bigserial → `BIGINT`; smallint/tinyint → `SMALLINT`;
varchar/nvarchar → `VARCHAR(255)`; char/nchar → `CHAR(1)`; text/long/clob → `TEXT`;
date/timestamp/datetime → `DATETIME`; smalldatetime → `SMALLDATETIME`;
bytea/blob → `IMAGE`; numeric/decimal → `NUMERIC(18,6)`; float/real → `FLOAT`;
double precision → `DOUBLE PRECISION`; boolean → `BIT`.

- **money** — ASE-native fixed-point currency type (also `smallmoney`).
- **text/image** — LOB types; written on a dedicated writer connection
  (`_writer_storage`), separate from the main insert. Set `syb_binary_images = 1`
  (via `connect_call_blob_setup`) to get raw binary instead of hex.
- **datetime / smalldatetime** — `SMALLDATETIME` has only minute precision.
  `on_connect_call => 'datetime_setup'` sets the output format with
  `syb_date_fmt('ISO_strict')`; only a DBD::Sybase too old to have
  `syb_date_fmt` gets `SET DATEFORMAT mdy` instead, with a warning — one or the
  other, never both. Custom format class parses `%Y-%m-%dT%H:%M:%S.%3NZ`,
  formats `%m/%d/%Y %H:%M:%S.%3N`.

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
  (bit `0x80`).
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
There is no native `OFFSET`; with an offset, `DBIO::Sybase::SQLMaker::apply_limit`
emulates it through the `GenericSubQ` dialect — a correlated
`WHERE (SELECT COUNT(*) ...) BETWEEN ? AND ?` over a stable main-source order.
It throws without an `order_by`, and when the order is based on sources other
than the main one. ASE also supports `TOP n`, but the driver uses `SET ROWCOUNT`.

## Identifier Quoting + Case Sensitivity

Quote char is **square brackets**: `sql_quote_char([qw/[ ]/])` → `[col]`. Case
sensitivity of identifiers and string comparisons is **server-dependent** (set by
the server's sort order / charset at install time); do not assume.

## Unicode

ASE Unicode types: `unichar` / `univarchar` / `unitext` (UTF-16). The server's
default charset (e.g. `iso_1`, `utf8`) governs `char`/`varchar`. Configure charset
on the connection rather than assuming UTF-8.

## Introspection Catalog

ASE has **no** `INFORMATION_SCHEMA` views (Msg 208 on 16.0) — that is SQL Server
and ANSI. The driver reads the system catalog (karr k48):

| What | Catalog | Detail |
|------|---------|--------|
| tables/views | `sysobjects` type `U`/`V` + `sysusers` (owner) | skip the system view `sysquerymetrics` |
| columns | `syscolumns` + `systypes` **on `usertype`** | `type` gives `intn`/`numericn` for nullable columns; `status & 8` nullable, `status & 0x80` identity; `length` (halve for `uni*`), `prec`/`scale` |
| defaults | `syscomments` where `id = syscolumns.cdefault` | text `DEFAULT  'x' ` (or `create default d as …`), split over rows |
| indexes | `sysindexes` indid 1..250, `index_col(tbl, indid, n, uid)` until NULL | `status & 2` unique, `& 2048` PK constraint (server-named `tbl_<objid>`); `keycnt` counts the row id on nonclustered |
| FKs | `sysreferences` `fokey1..16`/`refkey1..16` → `col_name()` | no `ON DELETE/UPDATE` in ASE (Msg 156) |
| view text | `syscomments` (whole `CREATE VIEW`, 255-char rows) | order `colid2, colid` |

Index names created with a quoted identifier keep the quotes in `sysindexes.name`.
Unique constraints are emitted as `CREATE UNIQUE INDEX`, not inline constraints; ASE
does not support `CHECK` constraints the way other engines do.

## Testing Env Vars

`DBIO_TEST_SYBASE_DSN` (used by the test suite). `DBIO_TEST_SYBASE_USER` /
`DBIO_TEST_SYBASE_PASS` by convention. `DBIO_SYBASE_FREETDS_NOWARN=1` silences the
FreeTDS-support warning. ASE has no `:memory:` DB — Deploy creates a temp database
`CREATE DATABASE <prefix><pid>_<time>` and drops it after compare.
