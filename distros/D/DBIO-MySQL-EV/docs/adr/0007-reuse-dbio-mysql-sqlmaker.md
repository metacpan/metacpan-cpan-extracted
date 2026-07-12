# ADR 0007 — Reuse DBIO::MySQL::SQLMaker rather than the base SQLMaker

- Status: accepted
- Date: 2026-06-21
- Tags: sqlmaker, reuse, drivers, defect, limit-dialect

## Context

`DBIO::MySQL::SQLMaker` already exists in the sibling synchronous driver and
carries MySQL's SQL-generation behaviour that the base `DBIO::SQLMaker` does not
have (`dbio-mysql/lib/DBIO/MySQL/SQLMaker.pm`):

- **MySQL `LIMIT [offset,] rows`** via an `apply_limit` override (lines 55-66) —
  *not* the standard `LIMIT rows OFFSET offset`.
- **`INSERT INTO t () VALUES ()`** for empty inserts (lines 72-88), because MySQL
  rejects the standard `INSERT INTO t DEFAULT VALUES`.
- **Self-referencing DML** auto-wrapped in a double subquery for `UPDATE`/`DELETE`
  that reference the target table (lines 101-168), which MySQL otherwise rejects.
- **`FOR UPDATE` / `FOR SHARE [OF …] [NOWAIT | SKIP LOCKED]`** locking DSL
  (lines 218-256), including the MySQL 8.0.1 modifiers.
- **`STRAIGHT_JOIN`** join hint (lines 91-99).

The synchronous `DBIO::MySQL::Storage` uses it via
`__PACKAGE__->sql_maker_class('DBIO::MySQL::SQLMaker')`
(`dbio-mysql/lib/DBIO/MySQL/Storage.pm:13`). This driver already declares
`requires 'DBIO::MySQL'` in its cpanfile, so the class is available.

The async-ness lives in *how a statement is executed and how its result is
delivered* (Futures, the pool, pipelining), **not** in *how the SQL text is built* —
SQL generation is identical whether dispatched over EV::MariaDB or DBI. So the
async driver should instantiate the same MySQL SQLMaker as the sync driver. This is
exactly the lesson the Pg sibling recorded in its ADR 0006 ("Reuse
DBIO::PostgreSQL::SQLMaker rather than forking the SQLMaker"), where wiring the
*base* `DBIO::SQLMaker` into the async driver silently dropped all PostgreSQL
operators (its karr #4).

## Decision

The async storage **should** use `DBIO::MySQL::SQLMaker` — the full MySQL
SQLMaker — and must not substitute the base `DBIO::SQLMaker` or a stripped maker:

- `sql_maker_class` defaults to `'DBIO::MySQL::SQLMaker'`; the module is loaded at
  compile time.
- `sql_maker` instantiates that class with MySQL quoting (`quote_char => '`'`,
  `name_sep => '.'`). The `apply_limit` override in `DBIO::MySQL::SQLMaker`
  provides MySQL's `LIMIT [offset,] rows`, so the storage must **not** pin
  `limit_dialect => 'LimitOffset'` (the standard `LIMIT … OFFSET …`), which would
  override or conflict with MySQL's syntax.
- All async DML (`select_async`, `insert_async`, `update_async`, `delete_async`)
  routes through this one `sql_maker`.

## Implementation

Implemented in karr #7. The async storage now wires the MySQL maker:

- `use DBIO::MySQL::SQLMaker;` and `sql_maker_class => 'DBIO::MySQL::SQLMaker'`
  (`lib/DBIO/MySQL/Async/Storage.pm:11,44`).
- `sql_maker` instantiates `DBIO::MySQL::SQLMaker` with MySQL quoting only
  (`quote_char => '`'`, `name_sep => '.'`); the dead `limit_dialect => 'LimitOffset'`
  arg was removed — limit handling comes from the maker's `apply_limit` override,
  not a constructor flag (`Storage.pm:188-197`).

`t/03-sql-maker-mysql.t` locks this in: it asserts the concrete
`DBIO::MySQL::SQLMaker` class and that pagination emits MySQL's `LIMIT ?, ?` (not
`OFFSET`). The pre-existing `isa_ok $sm, 'DBIO::SQLMaker'` could not catch the
defect, since the wrong maker ISA the base class; the new test fails against the
old wiring and passes against the fix.

This was the *exact* defect class the Pg sibling fixed in its ADR 0006: the async
path was one class off from the sync MySQL maker, silently losing MySQL-specific
generation — most visibly pagination (`LIMIT rows OFFSET offset` instead of MySQL's
`LIMIT offset, rows`), plus empty-insert syntax, self-referencing DML wrapping, and
the `FOR UPDATE … OF … NOWAIT/SKIP LOCKED` lock DSL.

## Rationale

MySQL's SQL generation is identical whether the query is dispatched synchronously
over DBI or asynchronously over EV::MariaDB; the difference is execution and
delivery, not the SQL string. Forking or under-specifying the SQLMaker for the
async driver means maintaining two views of MySQL's dialect and guaranteeing they
never drift — and the shipped state is precisely what drift looks like: standard
`OFFSET` pagination that MySQL does not use, and missing lock/insert/self-ref
handling. Reusing `DBIO::MySQL::SQLMaker` verbatim makes the sync driver's dialect
decisions (its ADRs 0003 self-referencing DML / lock DSL, and the `apply_limit`
override) apply unchanged to async queries, with no async-side duplication —
exactly the Pg sibling's resolution in its ADR 0006.

## Consequences

- Once wired, every MySQL SQL feature defined by `DBIO::MySQL::SQLMaker` —
  MySQL `LIMIT` syntax, empty-insert form, self-referencing DML wrapping, the lock
  DSL, `STRAIGHT_JOIN` — works in async queries identically to the sync driver, for
  free, with no async-side duplication.
- The driver already depends on `DBIO::MySQL` (cpanfile); the SQLMaker is reused,
  not vendored or forked. A change to MySQL SQL generation lands in one place and
  reaches both drivers.
- `sql_maker_class` stays configurable, but its default must be
  `'DBIO::MySQL::SQLMaker'`; defaulting it to the base maker reintroduces exactly
  this defect.
