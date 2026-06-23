# ADR 0006 — Reuse DBIO::PostgreSQL::SQLMaker rather than forking the SQLMaker

- Status: accepted
- Date: 2026-06-21
- Tags: sqlmaker, jsonb, reuse, drivers, bugfix

## Context

`DBIO::PostgreSQL::SQLMaker` already exists in the sibling synchronous driver and
carries all of PostgreSQL's SQL-generation behaviour. The headline part of that —
the native JSONB operators (`@>`, `<@`, `@?`, `@@`, `?`, `?|`, `?&`) registered
through core's `expand_op` mechanism, plus the `jsonb()` path DSL — is owned by
**dbio-postgresql ADR 0005** (native JSONB operators), which itself builds on core
ADR 0002 / 0004 (canonical `SQL::Abstract`, `disable_old_special_ops`,
`expand_op`). Those operator decisions are not restated here; this ADR is only
about *which SQLMaker class the async storage instantiates*.

The async driver generates SQL through a configurable `sql_maker_class`
(`Storage.pm:48`, `183`). The choice of class is load-bearing, and it was once
wrong.

## Decision

The async storage uses `DBIO::PostgreSQL::SQLMaker` — the full PostgreSQL
SQLMaker — and does not fork, subclass, or substitute a stripped-down maker.

- `sql_maker_class` defaults to `'DBIO::PostgreSQL::SQLMaker'`
  (`Storage.pm:48`); the module is loaded at compile time (`Storage.pm:11`).
- `sql_maker` instantiates that class with the PostgreSQL quoting/limit config —
  `quote_char => '"'`, `name_sep => '.'`, `limit_dialect => 'LimitOffset'`
  (`Storage.pm:180-190`).
- All async DML (`select_async`, `insert_async`, `update_async`, `delete_async`)
  and the identifier-quoting in `listen`/`unlisten`/`copy_in`/`notify` route
  through this one `sql_maker` (e.g. `Storage.pm:220`, `249`, `525`, `609`).

This was a real bug, not a hypothetical. The driver originally wired in the
*base* `DBIO::SQLMaker`, which has no knowledge of the JSONB operators, so async
queries silently lost all PostgreSQL-specific SQL generation. Fixed in commit
`07c6640` ("use DBIO::PostgreSQL::SQLMaker instead of base SQLMaker"), tracked as
karr #4 (style-audit fixes), which records: "Async driver had DBIO::SQLMaker
wired in — missing all JSONB operators (@>, <@, @?, @@, ?|&)."

## Rationale

PostgreSQL's SQL generation — JSONB operators, casts, the `?`-to-`jsonb_exists*`
rewrite, identifier quoting — is exactly identical whether the query is dispatched
synchronously over DBI or asynchronously over EV::Pg. The async-ness lives in
*how the statement is executed and how its result is delivered* (Futures, the
pool, pipelining), not in *how the SQL text is built*. Forking the SQLMaker for
the async driver would mean maintaining two copies of the operator set and
guaranteeing they never drift — the karr #4 bug is precisely what happens when the
async path is even one class off from the PostgreSQL maker. Reusing
`DBIO::PostgreSQL::SQLMaker` verbatim makes the JSONB decision in
dbio-postgresql ADR 0005 apply unchanged to async queries, with no second
implementation to keep in sync.

This is shipped and the regression is fixed and committed, hence **accepted**,
not proposed.

## Consequences

- Every PostgreSQL SQL feature defined by `DBIO::PostgreSQL::SQLMaker` — JSONB
  operators and the rest — works in async queries identically to the sync driver,
  for free, with no async-side duplication.
- The async driver takes a hard dependency on `DBIO::PostgreSQL` (for its
  SQLMaker); the SQLMaker is not vendored or forked. A change to PostgreSQL SQL
  generation lands in one place and reaches both drivers.
- `sql_maker_class` remains configurable (`Storage.pm:48`), so the class can be
  overridden — but overriding it with anything less than the PostgreSQL maker
  reintroduces exactly the karr #4 defect; the default must stay
  `DBIO::PostgreSQL::SQLMaker`.
- The JSONB operator semantics themselves are owned by dbio-postgresql ADR 0005
  (and core ADR 0002 / 0004); a change to how `expand_op` handlers render lands
  there, and this driver inherits it by reusing the class — it does not need its
  own regression for the operators beyond confirming the reuse wiring holds.
