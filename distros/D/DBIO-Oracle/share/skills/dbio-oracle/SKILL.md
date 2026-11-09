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
- No `.proverc`: set `PERL5LIB` to the local family checkouts, or `prove -l` uses an installed (older) dbio

## Key components

| Component | File | Purpose |
|-----------|------|---------|
| Schema entry | `lib/DBIO/Oracle.pm` | `use base 'DBIO::Base'` component + `storage_type` override on `connection`; loaded via `use DBIO Schema => -ora` or `load_components('Oracle')` |
| Storage | `lib/DBIO/Oracle/Storage.pm` | LOB binds, FK deferral, datetime setup, auto-increment via trigger inspection |
| SQLMaker | `lib/DBIO/Oracle/SQLMaker.pm` | CONNECT BY, PRIOR, 30-char identifier shortening |
| Introspect | `lib/DBIO/Oracle/Introspect.pm` + `Introspect/*.pm` | all_* views introspection |
| Diff | `lib/DBIO/Oracle/Diff.pm` + `Diff/*.pm` | Model comparison |
| Deploy | `lib/DBIO/Oracle/Deploy.pm` | `install`/`apply`; `diff`/`upgrade` via a temporary user (karr k36), new tables created whole (karr k37) |

## Storage quirks

- `sql_quote_char` = `"` (double-quote identifiers)
- `datetime_parser_type` = `DateTime::Format::Oracle`
- `sql_maker_class` = `DBIO::Oracle::SQLMaker`
- LOB comparisons split into 2000-char chunks via `DBMS_LOB.SUBSTR`
- Auto-increment: sequence detection via `ALL_TRIGGERS` BEFORE INSERT trigger inspection
- Savepoints: `_exec_svp_release` is a no-op (Oracle auto-releases)
- FK deferral: `ALTER SESSION SET CONSTRAINTS = DEFERRED/IMMEDIATE`
- `_connect_params_dsn` (core ADR 0057): DSN for `{ dbname, host, port }` without a DSN. No `host` → `dbi:Oracle:<dbname>` (name the Oracle client resolves); with `host` → Easy Connect `dbi:Oracle://<host>[:<port>][/<dbname>]`, `dbname` = service name (not SID), no port written when none given; `port` without `host` throws. Live-verified in `t/38-connect-params-live.t`

## Native deploy

```perl
# In Storage.pm (already added)
sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }
sub deploy_setup { }
```

`DBIO::Oracle::Deploy` (derives from core's `DBIO::Deploy::Base::TempDatabase`, ADR 0010): `install` (what `$schema->deploy` runs) and `apply` are inherited from `DBIO::Deploy::Base`. `diff`/`upgrade` build the desired state in a temporary user `DBIO_TMP_<pid>_<n>` (random password, quota on the caller's default tablespace, grants CREATE SESSION/TABLE/SEQUENCE/TRIGGER/VIEW), install + introspect on a connection of that user, `DROP USER … CASCADE` on every path; a failed drop warns with the user's name. The connected user needs `CREATE USER` and `DROP USER` (checked first via `session_privs`; a DBIO exception names the missing one before anything is created). `CREATE USER`/`GRANT`/`DROP USER` commit implicitly and run on a connection of their own, never the live `_dbh`, so the caller's transaction is untouched. Why not a savepoint: the first `CREATE TABLE` commits and erases it (ORA-01086, karr k36, `t/54` section 4). The diff creates a table only the target has whole (karr k37): `CREATE TABLE` with columns, primary key, `CONSTRAINT .. UNIQUE`, then sequence + `BEFORE INSERT` trigger (the install's; the model holds the sequence, not the trigger), then its indexes, then its foreign keys after every `CREATE TABLE`, all names quoted; no `DROP INDEX` after a `DROP TABLE` (ORA-01418); IDENTITY columns and tables without columns are refused. The column ALTERs quote their names like the install (karr k61); a dropped table also drops the sequences the install made for it (not an IDENTITY, not another schema's), and the model spells sequence names as the server has them (bare = upper case, quoted = as written). `DBIO::Oracle::Diff` built directly from two models does the same. The model carries view definitions (`views` section, `Introspect::Views`, `all_views.text`) and the diff writes `CREATE OR REPLACE VIEW` for a new or changed view, `DROP VIEW` for a gone one (drops before the tables, creates after; views on views ordered by `depends_on` from `all_dependencies`, a cycle refused; the view entry also holds `columns` (`all_tab_columns`, `COLUMN_ID` order) and the statement is `CREATE OR REPLACE VIEW v (cols) AS ..` so aliases from a column list survive, a changed list is a change; a view whose text is missing in the source or target model is refused naming it (never replaced every time); `Diff::View`, karr k65). A schema with `schema.table` sources gets one more temp user per foreign schema (see below). Tests: offline `t/58`, live `t/54`–`t/57`.

## Tables in another schema (karr k58)

A source named `schema.table` is a table in that schema (a user): DDL writes `"OWNX"."item"` (schema and table quoted as spelled; sequence, trigger, index and foreign keys qualified too; only an empty half is refused). `Deploy->install` checks `all_users` first and refuses a missing user loudly (no user is ever created). The connected user needs CREATE ANY TABLE/SEQUENCE/TRIGGER/INDEX, ALTER ANY TABLE (ORA-01031 / ORA-41900 without), DROP ANY ... for drops. `Introspect` `schemas => [..]` reads more schemas as `schema.table` keys; `Diff` writes such keys qualified. `Deploy->diff`/`upgrade` give each foreign schema a temporary user `DBIO_TMP_<pid>_<n>_<k>` (ADR 0011): DDL written with the temp users as qualifiers, each statement run as its schema's user, each user introspected on its own connection, merged and renamed back; all dropped on every path; a schema named like the connected user is its own (tables bare). Foreign keys across schemas: no GRANT is written, a missing REFERENCES is the server's error; only among its own temp users the deploy grants REFERENCES. Tests: offline `t/85`, `t/58` section 8, live `t/84` (second-user round needs `DBIO_TEST_ORA_EXTRAUSER_*`: `dbio_x` / `dbio_x_secret` on the maintainer's database).

## Offline tests

SQLMaker tests, load tests. Integration tests need `DBIO_TEST_ORA_DSN` (plus `_USER`, `_PASS`); live databases follow the house rules.

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
