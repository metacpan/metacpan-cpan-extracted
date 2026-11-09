# ADR 0006 — Reuse DBIO::PostgreSQL::SQLMaker rather than forking the SQLMaker

- Status: accepted
- Date: 2026-06-21
- Tags: sqlmaker, jsonb, reuse, drivers, bugfix
- Amended: `sql_maker` and the DML methods are core's, built from this dist's
  `sql_maker_class` / `_sql_maker_args`, and of the identifier quoting only
  `copy_in`'s still goes through the maker (see the Amendment); the decision
  itself stands

## Amendment (2026-10-05, karr k69) — the maker is the same; who builds it and what quotes through it is not

The decision this ADR records is in force and unchanged: the async storage
generates its SQL with `DBIO::PostgreSQL::SQLMaker`, not a fork, a subclass or
a stripped-down maker. Three statements of the *Decision* no longer describe
the code.

- **`sql_maker` is core's; this dist names the class and its arguments.** Since
  the thin-transport refactor (karr k22, commit `f4c527d`; core ADR 0030 §4)
  `DBIO::Storage::Async::sql_maker` builds and memoises the maker from two
  seams `DBIO::PostgreSQL::EV::Storage` fills: `sql_maker_class`, a method
  returning `'DBIO::PostgreSQL::SQLMaker'`, and `_sql_maker_args`, the quoting
  and limit configuration quoted below. `sql_maker_class` is therefore no
  longer a per-instance setting with a default: another maker comes only from
  a subclass overriding the method, and the warning in *Consequences* holds
  for that override unchanged.
- **The DML methods are core's.** `select_async`, `insert_async`,
  `update_async` and `delete_async` are inherited, and core's `_run_crud`
  builds their SQL with that one maker -- the property this ADR is about, kept
  by inheritance instead of by four methods here.
- **Of the identifier quoting, only `copy_in`'s goes through the maker.** It
  quotes the table and each column with `sql_maker->_quote`. `listen` and
  `unlisten` are core's (ADR 0003 amendment, core ADR 0056), and the channel
  their seams send has been quoted by `_pg_quote_channel` since karr k43
  (commit `ccdef86`): as one identifier, where the maker's `_quote` splits at
  the name separator and turned a channel with a `.` into a qualified name the
  server rejects. Since karr k55 (commit `e6d19e1`) that method delegates to
  `DBIO::PostgreSQL::Util::quote_channel`, the helper of the `DBIO::PostgreSQL`
  dist. `notify` quotes nothing, and did not when this ADR was written either:
  it binds the channel to `SELECT pg_notify($1, $2)` (ADR 0003). Naming it
  among the quoting callers was this ADR's mistake.

The `Storage.pm:NNN` references below were written against the file before
that refactor. None of them points at its target any more; they are left as
written.

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
karr k4 (style-audit fixes), which records: "Async driver had DBIO::SQLMaker
wired in — missing all JSONB operators (@>, <@, @?, @@, ?|&)."

## Rationale

PostgreSQL's SQL generation — JSONB operators, casts, the `?`-to-`jsonb_exists*`
rewrite, identifier quoting — is exactly identical whether the query is dispatched
synchronously over DBI or asynchronously over EV::Pg. The async-ness lives in
*how the statement is executed and how its result is delivered* (Futures, the
pool, pipelining), not in *how the SQL text is built*. Forking the SQLMaker for
the async driver would mean maintaining two copies of the operator set and
guaranteeing they never drift — the karr k4 bug is precisely what happens when the
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
  reintroduces exactly the karr k4 defect; the default must stay
  `DBIO::PostgreSQL::SQLMaker`.
- The JSONB operator semantics themselves are owned by dbio-postgresql ADR 0005
  (and core ADR 0002 / 0004); a change to how `expand_op` handlers render lands
  there, and this driver inherits it by reusing the class — it does not need its
  own regression for the operators beyond confirming the reuse wiring holds.
