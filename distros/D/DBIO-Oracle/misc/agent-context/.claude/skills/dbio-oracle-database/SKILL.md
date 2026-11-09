---
name: dbio-oracle-database
description: Use when you need Oracle specifics for driver work — DBD::Oracle, dialect, types, sequences and IDENTITY, transactions, pagination, identifier limits.
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
Driver declared by the schema (component, `-ora` or `storage_type`), not chosen by the DSN (core ADR 0067). `DBD::Oracle::VERSION >= 1.52` reports NCHAR/NVARCHAR2 size in characters; older reports UTF-16 bytes (driver applies `nchar_size_factor` of 2 to correct — `Introspect/Columns.pm`). Insert-returning supported on `normalized_dbms_version >= 8.001` (`Storage.pm`).

## Version Notes

| Feature | Available | Driver uses it? |
|---------|-----------|-----------------|
| `RETURNING ... INTO` | 8i+ | Yes (`SQLMaker::_insert_returning`) |
| `GENERATED AS IDENTITY` | 12c+ | Read, not written — introspected as auto-increment and `create()` without `RETURNING` reads the key from its sequence (`all_tab_identity_cols`); the install DDL writes a sequence + BEFORE INSERT trigger |
| `OFFSET .. FETCH FIRST/NEXT` | 12c+ | No — driver always uses ROWNUM subquery |
| 128-char identifiers | 12.2+ | No — driver enforces 30-char limit unconditionally |

## Type System

Driver canonical-to-Oracle mapping (`Type::map_dbio_type_to_oracle`):

| DBIO type | Oracle DDL |
|-----------|------------|
| integer/bigint/smallint | INTEGER |
| serial / bigserial | NUMBER(10) / NUMBER(20) |
| numeric/decimal `[p,s]` | NUMBER(p,s) |
| varchar / nvarchar | VARCHAR2(n) / NVARCHAR2(n) (default 255) |
| char / nchar | CHAR(n) / NCHAR(n) |
| text/long/clob | CLOB |
| boolean | NUMBER(1) |
| date | DATE |
| datetime / timestamp | TIMESTAMP[(n)] |
| timestamptz / timestamp with time zone | TIMESTAMP[(n)] WITH TIME ZONE |
| timestamp with local time zone | TIMESTAMP[(n)] WITH LOCAL TIME ZONE |
| real | BINARY_FLOAT |
| double precision | BINARY_DOUBLE |
| double | BINARY_DOUBLE (Oracle has no type DOUBLE) |
| float | FLOAT, FLOAT(n) for a size n of 1..126 |
| raw | RAW(n) |
| interval year to month / day to second | INTERVAL YEAR(n) TO MONTH / INTERVAL DAY(d) TO SECOND(s) |
| blob/bytea | BLOB |

Reverse (`map_dbd_type_to_dbio`, from `ALL_TAB_COLUMNS`): `INTEGER`/`SMALLINT` (precision NULL, scale 0, only those) → integer; `NUMBER(38)`/`NUMBER(38,0)` → numeric `[38,0]` (column diff compares `[p,0]` and `p` equal); `DATE` → date (size dropped; `BINARY_FLOAT`/`BINARY_DOUBLE` likewise stay `binary_float`/`binary_double`); `FLOAT` → float with size = `data_precision` (126 or none → float without size); VARCHAR2/CHAR with `char_used` 'C' read as size `"20 CHAR"` (string, written as `VARCHAR2(20 CHAR)`; BYTE keeps the number); VARCHAR2/NVARCHAR2/NCHAR/TIMESTAMP(n) keep their size (national types from `char_length`), written back as `VARCHAR2(n)` etc.; `TIMESTAMP(n) WITH [LOCAL] TIME ZONE` → `timestamp with [local] time zone` size n (6 = no size); a bare `NUMBER` (precision and scale NULL) is numeric. Column diff size key: `[p,0]`=p, timestamp 6 and float 126 = no size, `n BYTE`=n, `n CHAR` stays; NCHAR/NVARCHAR2 are always CHAR (written `NCHAR(5)`); float size must be an integer 1..126. RAW size is `data_length` (bytes, 16 for RAW(16)); `INTERVAL YEAR(n) TO MONTH` reads as `interval year to month` size n, `INTERVAL DAY(d) TO SECOND(s)` as `[d,s]` (defaults 2 and 2,6 = no size) and both are written with their precision; nvarchar is NVARCHAR2. The column diff compares data types by the Oracle type they render (varchar = varchar2, datetime = timestamp, real = binary_float). `long` is still written as CLOB (not changed, only noted). New-table DDL goes through `map_dbio_type_to_oracle` as well. LOB types (BLOB/CLOB/NCLOB) carry no size.

## Identity / Last-Insert-Id

No auto-increment column type used. A column is "auto-increment" when a sequence feeds it via a BEFORE INSERT trigger. Driver introspects `ALL_TRIGGERS.TRIGGER_BODY` for `seq.nextval` and `:new.col` (`Storage/AutoIncrement.pm`, `Introspect/Columns.pm`); throws if a column maps to multiple/ambiguous sequences — then specify `sequence` in column_info explicitly. INSERT uses `RETURNING col INTO ?` (`_use_insert_returning_bound`); `_dbh_last_insert_id` falls back to `seq.CURRVAL` from DUAL. DDL emits `CREATE SEQUENCE <table_col_seq>` (`DDL.pm`), name run through the shortener.

## Transactions & Savepoints

Standard COMMIT/ROLLBACK. Savepoints (`Storage/Savepoints.pm`): `SAVEPOINT name`, `ROLLBACK TO SAVEPOINT name`. Release is a no-op — Oracle auto-releases a savepoint on same-name reuse. FK deferral (`Storage/FKDeferral.pm`): `ALTER SESSION SET CONSTRAINTS = DEFERRED` around the work, then `= IMMEDIATE`; constraints must be declared `DEFERRABLE`.

## Pagination

Oracle has no `LIMIT`. Driver `apply_limit` always delegates to the inherited `_RowNum` dialect — a ROWNUM-based subquery wrap (`SQLMaker::apply_limit`). It does NOT use 12c `OFFSET .. FETCH`, regardless of server version.

## Identifiers

- Quote char `"` (`sql_quote_char`). Unquoted identifiers fold to UPPERCASE — driver uppercases table/owner names when no quote char is in play (`AutoIncrement`, introspection passes `owner = USER`).
- A table named `schema.table` lives in that schema (a user): schema and table are quoted apart, as spelled (`"OWNX"."t"`); upper case for a user made unquoted. Writing into another user needs the `CREATE ANY TABLE` etc. system privileges; the user must exist (`all_users`).
- 30-byte limit (pre-12.2). One shared algorithm in `DBIO::Oracle::Identifier::shorten`: names ≤30 chars pass through; longer ones are CamelCase-compressed (vowels trimmed if still too long), then suffixed `_<base36 MD5>` for stable, collision-resistant uniqueness. Used at both query time (`SQLMaker::_shorten_identifier`, relation aliases via `relname_to_table_alias`) and deploy time (sequence/index names) so generated and referenced names match. Requires Digest::MD5, Math::BigInt, Math::Base36.

## Hierarchical Queries

`CONNECT BY` / `START WITH` / `ORDER SIBLINGS BY` and the `PRIOR` operator via resultset attrs `connect_by`, `connect_by_nocycle`, `start_with`, `order_siblings_by` (`SQLMaker._connect_by`). Pre-9 `(+)` outer joins live in `SQLMaker/Joins.pm` + `Storage/WhereJoins.pm`.

## Unicode / NLS

`datetime_parser_type` = `DateTime::Format::Oracle`. On every connect, with no `on_connect_call` needed (`Storage/ConnectSetup`: `_apply_connection_schema` calls `connect_call_datetime_setup`; naming `datetime_setup` as well is harmless) the session sets `NLS_DATE_FORMAT` = `YYYY-MM-DD HH24:MI:SS`, `NLS_TIMESTAMP_FORMAT` (`.FF`), `NLS_TIMESTAMP_TZ_FORMAT` (`.FF TZHTZM`), overridable via the matching env vars. Database charset should be `AL32UTF8` for full Unicode; `NVARCHAR2`/`NCHAR` use the national charset (`AL16UTF16`). `sysdate` default introspected as `current_timestamp`.

## Introspection Catalog

`ALL_*` views (owner-scoped), per `Introspect/*.pm`: `ALL_TABLES`, `ALL_TAB_COLUMNS`, `ALL_CONSTRAINTS`, `ALL_CONS_COLUMNS`, `ALL_INDEXES`, `ALL_IND_COLUMNS`, `ALL_TRIGGERS`, `ALL_VIEWS`. Deploy (`Deploy.pm`): `install` (what `$schema->deploy` runs) and `apply` work; `diff` and `upgrade` build the desired state in a temporary user `DBIO_TMP_<pid>_<n>` (needs `CREATE USER`/`DROP USER`; a test deploy on the live connection cannot be rolled back, DDL commits implicitly, so `CREATE USER`/`GRANT`/`DROP USER` run on a connection of their own); the diff creates a table only the target has whole (karr k37): columns, keys, sequence and trigger, then its indexes, then its foreign keys, every name quoted.

## LOBs

CLOB/BLOB binds via `ora_type => ORA_CLOB/ORA_BLOB` (`Type::oracle_lob_bind_attrs`). Comparisons split into 2000-char chunks via `DBMS_LOB.SUBSTR`. Multi-part LOB binds disable sth caching (`Storage._dbh_execute`).

## Testing Env Vars

`DBIO_TEST_ORA_DSN`, `DBIO_TEST_ORA_USER`, `DBIO_TEST_ORA_PASS`. Cross-schema tests also need `DBIO_TEST_ORA_EXTRAUSER_DSN`/`_USER`/`_PASS` (a *different* Oracle user). Tests skip when unset.
