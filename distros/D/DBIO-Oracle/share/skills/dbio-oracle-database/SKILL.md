---
name: dbio-oracle-database
description: "Oracle Database knowledge for Perl driver development (DBD::Oracle, SQL dialect, types, sequences/IDENTITY, transactions, pagination, identifier limits)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Oracle Database for Perl DB driver development. Trust the driver code over generic Oracle knowledge if they conflict.

## DBD::Oracle

Connection via DSN, optionally a TNS service name / EZConnect:
```perl
DBI->connect("dbi:Oracle:SID", $user, $pass)
DBI->connect("dbi:Oracle:host=db;port=1521;service_name=ORCLPDB1", $user, $pass)
```
Driver auto-detected from `dbi:Oracle:` DSN. `DBD::Oracle::VERSION >= 1.52` reports NCHAR/NVARCHAR2 size in characters; older reports UTF-16 bytes (driver applies `nchar_size_factor` of 2 to correct — `Introspect/Columns.pm`). Insert-returning supported on `normalized_dbms_version >= 8.001` (`Storage.pm`).

## Version Notes

| Feature | Available | Driver uses it? |
|---------|-----------|-----------------|
| `RETURNING ... INTO` | 8i+ | Yes (`SQLMaker::_insert_returning`) |
| `GENERATED AS IDENTITY` | 12c+ | No — driver uses sequence + BEFORE INSERT trigger |
| `OFFSET .. FETCH FIRST/NEXT` | 12c+ | No — driver always uses ROWNUM subquery |
| 128-char identifiers | 12.2+ | No — driver enforces 30-char limit unconditionally |

## Type System

Driver canonical-to-Oracle mapping (`Type::map_dbio_type_to_oracle`):

| DBIO type | Oracle DDL |
|-----------|------------|
| integer/bigint/smallint | NUMBER |
| serial / bigserial | NUMBER(10) / NUMBER(20) |
| numeric/decimal `[p,s]` | NUMBER(p,s) |
| varchar/nvarchar | VARCHAR2(n) (default 255) |
| char/nchar | CHAR(n)/NCHAR(n) |
| text/long/clob | CLOB |
| boolean | NUMBER(1) |
| date | DATE; datetime/timestamp | TIMESTAMP |
| timestamptz | TIMESTAMP WITH TIME ZONE |
| real | BINARY_FLOAT; float/double precision | BINARY_DOUBLE |
| blob/bytea | BLOB |

Reverse (`map_dbd_type_to_dbio`, from `ALL_TAB_COLUMNS`): `NUMBER(38,0)` → integer; `DATE` → datetime; `FLOAT` ≤63 → real else double precision; RAW size is bytes/2. LOB types (BLOB/CLOB/NCLOB) carry no size.

## Identity / Last-Insert-Id

No auto-increment column type used. A column is "auto-increment" when a sequence feeds it via a BEFORE INSERT trigger. Driver introspects `ALL_TRIGGERS.TRIGGER_BODY` for `seq.nextval` and `:new.col` (`Storage/AutoIncrement.pm`, `Introspect/Columns.pm`); throws if a column maps to multiple/ambiguous sequences — then specify `sequence` in column_info explicitly. INSERT uses `RETURNING col INTO ?` (`_use_insert_returning_bound`); `_dbh_last_insert_id` falls back to `seq.CURRVAL` from DUAL. DDL emits `CREATE SEQUENCE <table_col_seq>` (`DDL.pm`), name run through the shortener.

## Transactions & Savepoints

Standard COMMIT/ROLLBACK. Savepoints (`Storage/Savepoints.pm`): `SAVEPOINT name`, `ROLLBACK TO SAVEPOINT name`. Release is a no-op — Oracle auto-releases a savepoint on same-name reuse. FK deferral (`Storage/FKDeferral.pm`): `ALTER SESSION SET CONSTRAINTS = DEFERRED` around the work, then `= IMMEDIATE`; constraints must be declared `DEFERRABLE`.

## Pagination

Oracle has no `LIMIT`. Driver `apply_limit` always delegates to the inherited `_RowNum` dialect — a ROWNUM-based subquery wrap (`SQLMaker::apply_limit`). It does NOT use 12c `OFFSET .. FETCH`, regardless of server version.

## Identifiers

- Quote char `"` (`sql_quote_char`). Unquoted identifiers fold to UPPERCASE — driver uppercases table/owner names when no quote char is in play (`AutoIncrement`, introspection passes `owner = USER`).
- 30-byte limit (pre-12.2). One shared algorithm in `DBIO::Oracle::Identifier::shorten`: names ≤30 chars pass through; longer ones are CamelCase-compressed (vowels trimmed if still too long), then suffixed `_<base36 MD5>` for stable, collision-resistant uniqueness. Used at both query time (`SQLMaker::_shorten_identifier`, relation aliases via `relname_to_table_alias`) and deploy time (sequence/index names) so generated and referenced names match. Requires Digest::MD5, Math::BigInt, Math::Base36.

## Hierarchical Queries

`CONNECT BY` / `START WITH` / `ORDER SIBLINGS BY` and the `PRIOR` operator via resultset attrs `connect_by`, `connect_by_nocycle`, `start_with`, `order_siblings_by` (`SQLMaker._connect_by`). Pre-9 `(+)` outer joins live in `SQLMaker/Joins.pm` + `Storage/WhereJoins.pm`.

## Unicode / NLS

`datetime_parser_type` = `DateTime::Format::Oracle`. On connect (`Storage/ConnectSetup::connect_call_datetime_setup`) the session sets `NLS_DATE_FORMAT` = `YYYY-MM-DD HH24:MI:SS`, `NLS_TIMESTAMP_FORMAT` (`.FF`), `NLS_TIMESTAMP_TZ_FORMAT` (`.FF TZHTZM`), overridable via the matching env vars. Database charset should be `AL32UTF8` for full Unicode; `NVARCHAR2`/`NCHAR` use the national charset (`AL16UTF16`). `sysdate` default introspected as `current_timestamp`.

## Introspection Catalog

`ALL_*` views (owner-scoped), per `Introspect/*.pm`: `ALL_TABLES`, `ALL_TAB_COLUMNS`, `ALL_CONSTRAINTS`, `ALL_CONS_COLUMNS`, `ALL_INDEXES`, `ALL_IND_COLUMNS`, `ALL_TRIGGERS`, `ALL_VIEWS`. Deploy (`Deploy.pm`) is test-deploy-and-compare: introspect live → deploy to temp → introspect temp → diff.

## LOBs

CLOB/BLOB binds via `ora_type => ORA_CLOB/ORA_BLOB` (`Type::oracle_lob_bind_attrs`). Comparisons split into 2000-char chunks via `DBMS_LOB.SUBSTR`. Multi-part LOB binds disable sth caching (`Storage._dbh_execute`).

## Testing Env Vars

`DBIO_TEST_ORA_DSN`, `DBIO_TEST_ORA_USER`, `DBIO_TEST_ORA_PASS`. Cross-schema tests also need `DBIO_TEST_ORA_EXTRAUSER_DSN`/`_USER`/`_PASS` (a *different* Oracle user). Tests skip when unset.
