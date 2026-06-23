# ADR 0001 — Foreign keys are omitted from install DDL

- Status: accepted
- Date: 2026-06-09

## Context

DuckDB accepts `FOREIGN KEY` declarations but does **not** enforce them at
runtime (as of the 1.x series). It *is*, however, strict at `CREATE TABLE`
time: the referenced column tuple must match a `PRIMARY KEY` or `UNIQUE`
constraint on the parent table **in the same column order**.

DBIO Result classes routinely declare relationships with condition hashes
whose key order is alphabetical, not parent-PK order. Emitting those FKs in
the install DDL makes DuckDB reject the `CREATE TABLE` outright, even though
the constraint would have no runtime effect.

A cross-driver architecture review (2026-06-09) flagged the apparent gap
that `DBIO::DuckDB::Diff` does not diff foreign keys on existing tables, and
suggested adding a standalone `Diff/ForeignKey.pm`.

## Decision

1. `DBIO::DuckDB::DDL` does **not** emit `FOREIGN KEY` clauses in install
   DDL. Referential integrity is left to application logic.
2. `DBIO::DuckDB::Diff::Table` still emits inline `FOREIGN KEY` clauses for a
   *new* table when the target model carries them (e.g. a model hand-built
   or introspected from a database where FKs were added via raw SQL).
3. We do **not** add a standalone FK differ for existing tables.

The reason for (3): under the test-deploy-and-compare flow the target model
is introspected from a throwaway DB that was built from the install DDL —
which omits FKs per (1). A standalone FK differ would therefore see FKs on
the live source but none on the target and emit a spurious `DROP`/recreate
on every run, breaking diff idempotency. The feature is only meaningful once
DuckDB enforces FKs and the DDL can emit them in a parent-PK-ordered form.

## Consequences

- Schemas deploy cleanly regardless of FK condition key order.
- FK drift on existing tables is invisible to `diff`/`upgrade`. Acceptable
  while DuckDB does not enforce FKs.
- Revisit if/when DuckDB enforces foreign keys: at that point DDL should
  emit FKs (in parent-PK column order) and a `Diff/ForeignKey.pm` becomes
  safe to add.

## Future architecture work (tracked cross-repo, not here)

The same review found that the `install`/`apply`/`upgrade` Deploy
orchestration and the FK row-grouping loop in `Introspect/ForeignKeys.pm`
are copied near-identically across the DuckDB, MySQL and PostgreSQL drivers.
Consolidating those into core base classes (`DBIO::Deploy::Base`, and
adopting `DBIO::Introspect::Base::_aggregate_by_ordered`) is a cross-repo
change owned by dbio core — doing it in one driver alone would create
divergence, so it is filed as a core ticket rather than done here.
