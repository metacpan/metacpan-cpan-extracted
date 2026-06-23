---
name: dbio-oracle
description: "DBIO::Oracle driver — Oracle storage, CONNECT BY/PRIOR SQL, identifier shortening, LOB handling, ALL_* introspection"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Oracle

Oracle driver for DBIO. Entry point: `DBIO::Oracle`.

## Quick facts

- Distribution: DBIO-Oracle
- DBD driver: DBD::Oracle
- Auto-detected from `dbi:Oracle:` DSN
- Heritage = 1 (DBIO + DBIx::Class dual copyright)
- No `.proverc` (tests run against installed dbio, not local source)

## Key components

| Component | File | Purpose |
|-----------|------|---------|
| Schema entry | `lib/DBIO/Oracle.pm` | `use base 'DBIO::Core'` + storage override |
| Storage | `lib/DBIO/Oracle/Storage.pm` | LOB binds, FK deferral, datetime setup, auto-increment via trigger inspection |
| SQLMaker | `lib/DBIO/Oracle/SQLMaker.pm` | CONNECT BY, PRIOR, 30-char identifier shortening |
| Introspect | `lib/DBIO/Oracle/Introspect.pm` + `Introspect/*.pm` | all_* views introspection |
| Diff | `lib/DBIO/Oracle/Diff.pm` + `Diff/*.pm` | Model comparison |
| Deploy | `lib/DBIO/Oracle/Deploy.pm` | Test-deploy-and-compare orchestrator |

## Storage quirks

- `sql_quote_char` = `"` (double-quote identifiers)
- `datetime_parser_type` = `DateTime::Format::Oracle`
- `sql_maker_class` = `DBIO::Oracle::SQLMaker`
- LOB comparisons split into 2000-char chunks via `DBMS_LOB.SUBSTR`
- Auto-increment: sequence detection via `ALL_TRIGGERS` BEFORE INSERT trigger inspection
- Savepoints: `_exec_svp_release` is a no-op (Oracle auto-releases)
- FK deferral: `ALTER SESSION SET CONSTRAINTS = DEFERRED/IMMEDIATE`

## Native deploy

```perl
# In Storage.pm (already added)
sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }
sub deploy_setup { }
```

`DBIO::Oracle::Deploy` uses test-deploy-and-compare: introspect live DB → deploy to temp → introspect temp → diff.

## Offline tests

SQLMaker tests, load tests. Integration tests need `DBIO_TEST_ORA_DSN`.

## Common tasks

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-oracle

# Build
dzil build

# Test (against installed dbio)
prove -l t/

# Install deps
cpanm --installdeps .

# Release (user only)
dzil release
```
