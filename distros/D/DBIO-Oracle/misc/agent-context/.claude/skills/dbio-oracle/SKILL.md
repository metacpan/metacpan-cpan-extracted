---
name: dbio-oracle
description: Load when working on the DBIO::Oracle driver — storage, CONNECT BY/PRIOR, identifier shortening, LOB handling, ALL_* introspection.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Oracle

Oracle driver for DBIO. Entry point: `DBIO::Oracle`.

## Quick facts

- Distribution: DBIO-Oracle
- DBD driver: DBD::Oracle
- Declared by the component, `-ora` or `storage_type`; never chosen by the DSN (core ADR 0067). Tests on the shared `DBIO::Test::Schema` declare `+DBIO::Oracle::Storage` on a clone
- Heritage = 1 (DBIO + DBIx::Class dual copyright)
- Run tests through `../dbio/maint/capped-test` (it puts the local family checkouts first)

## Key components

| Component | File | Purpose |
|-----------|------|---------|
| Schema entry | `lib/DBIO/Oracle.pm` | `use base 'DBIO::Base'` component + `storage_type` override on `connection`; loaded via `use DBIO Schema => -ora` or `load_components('Oracle')` |
| Storage | `lib/DBIO/Oracle/Storage.pm` | LOB binds, FK deferral, datetime setup, auto-increment via trigger inspection |
| SQLMaker | `lib/DBIO/Oracle/SQLMaker.pm` | CONNECT BY, PRIOR, 30-char identifier shortening |
| Introspect | `lib/DBIO/Oracle/Introspect.pm` + `Introspect/*.pm` | all_* views introspection |
| Diff | `lib/DBIO/Oracle/Diff.pm` + `Diff/*.pm` | Model comparison |
| Deploy | `lib/DBIO/Oracle/Deploy.pm` | `install`/`apply`; `diff`/`upgrade` via a temporary user, new tables created whole |

## Storage quirks

- `sql_quote_char` = `"` (double-quote identifiers)
- `datetime_parser_type` = `DateTime::Format::Oracle`
- `sql_maker_class` = `DBIO::Oracle::SQLMaker`
- LOB comparisons split into parts via `DBMS_LOB.SUBSTR` (`Storage/LOBSupport.pm`): text in 1000-character parts, binary in 2000-byte parts compared with `HEXTORAW(?)`; an empty value is `DBMS_LOB.GETLENGTH(col) = 0`
- Auto-increment: sequence detection via `ALL_TRIGGERS` BEFORE INSERT trigger inspection
- Savepoints: `_exec_svp_release` is a no-op (Oracle auto-releases)
- FK deferral: `ALTER SESSION SET CONSTRAINTS = DEFERRED/IMMEDIATE`
- `_connect_params_dsn` (core ADR 0057): DSN for `{ dbname, host, port }` without a DSN. No `host` → `dbi:Oracle:<dbname>` (name the Oracle client resolves); with `host` → Easy Connect `dbi:Oracle://<host>[:<port>][/<dbname>]`, `dbname` = service name (not SID), no port written when none given; `port` without `host` throws. Live-verified in `t/38-connect-params-live.t`

## Capabilities

- `_use_transactional_ddl(0)`: DDL commits implicitly, so core runs a deploy without a transaction bracket (`Storage.pm`).
- `_use_set_operator_all_family(0)`: the `... ALL` set operators are refused by default; the class-level opt-in lifts it for Oracle 21c and later (ADR 0039).
- `_use_supports_exists_query(1)`: the 1/0 statement behind `results_exist` ends in `FROM DUAL` (`_exists_value_sql`, ADR 0037).
- Upsert: `$rs->upsert` is refused (`supports_upsert` is the core default 0); the MERGE design is ADR 0036.

## Native deploy

```perl
# In Storage.pm
sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }
sub deploy_setup { }
```

`DBIO::Oracle::Deploy` derives from core's `DBIO::Deploy::Base::TempDatabase` (ADR 0010). `install` (what `$schema->deploy` runs) and `apply` are inherited from `DBIO::Deploy::Base`.

### diff and upgrade

- The desired state is built in a temporary user `DBIO_TMP_<pid>_<n>`: random password, quota on the caller's default tablespace, grants CREATE SESSION/TABLE/SEQUENCE/TRIGGER/VIEW.
- Install and introspection run on a connection of that user; `DROP USER ... CASCADE` runs on every path, and a failed drop warns with the user's name.
- The connected user needs `CREATE USER` and `DROP USER` (checked first via `session_privs`; a DBIO exception names the missing one before anything is created).
- `CREATE USER`/`GRANT`/`DROP USER` commit implicitly and run on a connection of their own, never the live `_dbh`, so the caller's transaction is untouched. A savepoint cannot hold the test deploy: the first `CREATE TABLE` commits (ADR 0010).

### Diff output

- A table only the target has is created whole: `CREATE TABLE` with columns, primary key, `CONSTRAINT .. UNIQUE`, then sequence + `BEFORE INSERT` trigger (the install's; the model holds the sequence, not the trigger), then its indexes, then its foreign keys after every `CREATE TABLE`, all names quoted.
- No `DROP INDEX` follows a `DROP TABLE` (ORA-01418). A dropped table also drops the sequences the install made for it (not an IDENTITY, not another schema's). The model spells sequence names as the server has them (bare = upper case, quoted = as written).
- IDENTITY columns and tables without columns are refused. Column ALTERs quote their names like the install.
- `DBIO::Oracle::Diff` built directly from two models does the same.
- Tests: offline `t/58`, live `t/54`-`t/57`.

### Views

- The model carries view definitions (`views` section, `Introspect::Views`, `all_views.text`); the diff (`Diff::View`) writes `CREATE OR REPLACE VIEW` for a new or changed view and `DROP VIEW` for a gone one (drops before the tables, creates after).
- Views on views are ordered by `depends_on` from `all_dependencies`; a cycle is refused.
- The view entry also holds `columns` (`all_tab_columns`, `COLUMN_ID` order); the statement is `CREATE OR REPLACE VIEW v (cols) AS ..`, so aliases from a column list survive and a changed list is a change.
- A view whose text is missing in the source or target model is refused naming it (never replaced on every run).

## Tables in another schema (ADR 0011)

- A source named `schema.table` is a table in that schema (a user). DDL writes `"OWNX"."item"` (schema and table quoted as spelled; sequence, trigger, index and foreign keys qualified too; only an empty half is refused).
- `Deploy->install` checks `all_users` first and refuses a missing user loudly (no user is ever created).
- The connected user needs CREATE ANY TABLE/SEQUENCE/TRIGGER/INDEX, ALTER ANY TABLE (ORA-01031 / ORA-41900 without), DROP ANY ... for drops.
- `Introspect` `schemas => [..]` reads more schemas as `schema.table` keys; `Diff` writes such keys qualified.
- `Deploy->diff`/`upgrade` give each foreign schema a temporary user `DBIO_TMP_<pid>_<n>_<k>`: DDL written with the temp users as qualifiers, each statement run as its schema's user, each user introspected on its own connection, merged and renamed back; all dropped on every path. A schema named like the connected user is its own (tables bare).
- Foreign keys across schemas: no GRANT is written, a missing REFERENCES is the server's error; only among its own temp users the deploy grants REFERENCES.
- Tests: offline `t/85`, `t/58` section 8, live `t/84`. The second-user round needs `DBIO_TEST_ORA_EXTRAUSER_DSN/_USER/_PASS` (a different Oracle user, see `t/84-ddl-cross-schema-live.t` and `maint/k8s/oracle.yaml`).

## Offline tests

SQLMaker tests, load tests. Integration tests need `DBIO_TEST_ORA_DSN` (plus `_USER`, `_PASS`); live databases, caps and preflight follow the house rules and `references/live-testing.md` of `dbio-driver-development`.

## Common tasks

```bash
cd <your dbio-oracle checkout>

# Build
dzil build

# Test (recursive, through the wrapper; offline without DBIO_TEST_ORA_*)
../dbio/maint/capped-test prove -lr t/

# Install deps
cpanm --installdeps .

# Release (user only)
dzil release
```
