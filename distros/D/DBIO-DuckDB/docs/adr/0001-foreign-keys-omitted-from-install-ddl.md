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

## Addendum 2026-10-20 (karr k48)

The maintainer confirmed (3): FK changes on existing tables are not diffed,
and neither as a report-only diff nor via a table rebuild. The gap is named
in `CLAUDE.md` and the `DBIO::DuckDB::Diff` POD. Independent of that,
`Introspect::ForeignKeys` returns the live name as `constraint_name`
(ADR 0021 in core) instead of `fk_id`. The install DDL still writes no FKs.

## Addendum 2026-10-25 — DuckDB enforces foreign keys; the DDL writes them (karr k49)

Premise (1) and (3) no longer hold, and the decision above is replaced by the
maintainer's decision of 2026-10-25, taken with the Conformance lists of core
(ADR 0060). Measured on libduckdb 1.5.3: DuckDB **does** enforce a foreign key
on insert and delete. It still takes a key only to the columns of a PRIMARY KEY
or UNIQUE constraint of the parent **in that constraint's own order**
(`does not have a primary key or unique constraint on the columns b,a`), it
has no `ALTER TABLE ... ADD / DROP FOREIGN KEY`, and its parser refuses
`ON DELETE / ON UPDATE CASCADE`, `SET NULL` and `SET DEFAULT`
(`FOREIGN KEY constraints cannot use CASCADE, SET NULL or SET DEFAULT`; RESTRICT
and NO ACTION are taken).

Decision:

1. `DBIO::DuckDB::DDL` writes the `FOREIGN KEY` clause of every `belongs_to`
   that is a foreign key constraint. The column pairs are laid out in the order
   of the parent's key, which is what the old objection ("alphabetically sorted
   conditions") needed; the same key declared twice is written once; a parent
   column set that is neither the PRIMARY KEY nor a UNIQUE constraint is
   refused, naming both tables and the columns. Tables come after the tables
   their keys point to (the existing dependency order); a circle of keys is
   refused naming the relationship, since both tables are created whole and no
   key can be added later.
2. `CASCADE`, `SET NULL` and `SET DEFAULT` are refused before the first
   statement, with table and columns, not silently dropped.
3. (Superseded 2026-10-26 by ADR 0010: the table is rebuilt; only a table
   another table points to, or one that points to itself, is refused.)
   A foreign key to add to or drop from a table that exists is refused by
   `Deploy->diff` (and `apply`), before any statement, naming the table and the
   key. This replaces the decision of addendum 2026-10-20 ("not diffed"): a
   difference that can neither be applied nor ignored is reported. A table the
   diff creates brings its keys, after the tables they point to, and a table is
   dropped before the tables it points to.
4. Introspection reads a key through `duckdb_constraints()`, which keeps the
   column lists in order and side by side; the joins of `information_schema`
   paired every key column with every parent column.

The test fixture of core declares CASCADE / SET NULL and a circle of keys
(`cd` and `track`); `DBIO::DuckDB::Test->init_schema` takes those off its own
copy of the sources, the fixture classes are untouched.

## Future architecture work (tracked cross-repo, not here)

The same review found that the `install`/`apply`/`upgrade` Deploy
orchestration and the FK row-grouping loop in `Introspect/ForeignKeys.pm`
are copied near-identically across the DuckDB, MySQL and PostgreSQL drivers.
Consolidating those into core base classes (`DBIO::Deploy::Base`, and
adopting `DBIO::Introspect::Base::_aggregate_by_ordered`) is a cross-repo
change owned by dbio core — doing it in one driver alone would create
divergence, so it is filed as a core ticket rather than done here.
