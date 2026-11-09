# ADR 0004 — The DDL layer emits no foreign keys (and no unique constraints)

*Revised by the Addendum (2026-10-26): the omission is no longer silent, the DDL refuses.*

- Status: accepted
- Date: 2026-07-25

## Context

Every other DBIO driver's `install_ddl` turns a result class's `belongs_to`
relationships into `FOREIGN KEY ... REFERENCES ...` clauses, and its
`add_unique_constraint` declarations into `UNIQUE` clauses. `dbio-db2` even
gives each FK a deterministic name so the diff layer can round-trip it
(db2 ADR 0005). The question for ClickHouse is whether `DBIO::ClickHouse::DDL`
should do the same.

ClickHouse has **no foreign key concept at all**. This is stronger than the
`dbio-duckdb` situation, where FK syntax exists and is parsed but not enforced
at runtime (duckdb ADR 0001 skips emitting them because DuckDB validates the
referenced column tuple at `CREATE TABLE` time and DBIO's alphabetically-sorted
condition hashes do not match parent key order). In ClickHouse the clause is not
merely unenforced: there is no foreign key syntax in the `CREATE TABLE` grammar
at all, so emitting one would at best be dead weight and at worst fail the
statement outright — on the first table that has a `belongs_to`.

The same is true of `UNIQUE`: ClickHouse has no unique constraint and no unique
index. Deduplication is a property of the table engine (`ReplacingMergeTree`
collapses rows sharing the `ORDER BY` key at merge time, asynchronously), not a
constraint the server can enforce on insert.

Referential integrity itself is out of character for the engine. ClickHouse is
an OLAP store built around bulk append and background merges; there is no
transaction to make a constraint check atomic against (ADR 0002), and joins are
resolved at query time without any declared relationship.

## Decision

`DBIO::ClickHouse::DDL` emits **no `FOREIGN KEY` clauses and no `UNIQUE`
clauses**, ever. Relationship metadata and `add_unique_constraint` declarations
stay purely on the DBIO side, where they still drive `related_resultset`,
`find`, and prefetch.

Two consequences follow directly and are part of this decision:

1. **No topological sort.** With no FKs there are no inter-table dependencies,
   so `install_ddl` emits sources in plain sorted-name order. That order is
   deterministic, which is what the diff layer actually needs.
2. **The MergeTree sorting key carries the identity story instead.** `ORDER BY`
   defaults to the DBIO primary key, and a caller who wants last-write-wins
   deduplication on that key opts into `ReplacingMergeTree` through
   `clickhouse_table`.

## Consequences

- Generated DDL is executable against a real server rather than failing at the
  first `belongs_to`, which is the whole point.
- **Referential integrity is the application's job.** Nothing in the database
  will reject an orphaned row. This is a property of ClickHouse, not a gap in
  the driver, and it is documented in `DBIO::ClickHouse::DDL`.
- **A `UNIQUE` declaration is a lie if read as a guarantee.** DBIO will happily
  use it for `find`; the server will happily store duplicates. The DDL POD says
  so explicitly and points at `ReplacingMergeTree`.
- The introspect/diff layer (follow-up ticket) never has to reconcile FK or
  unique state, because neither side can produce any: not the desired-state
  DDL, and not `SHOW CREATE TABLE`. This removes the entire FK-diff problem
  class that `dbio-db2` and `dbio-postgresql` had to solve.
- If a future ClickHouse release adds a constraint mechanism (the engine does
  already have `CONSTRAINT ... CHECK`, which is validated on insert), adding it
  is a new decision on top of this one, not a reversal — this ADR is about
  referential and uniqueness constraints specifically.

## Addendum (2026-10-26) — the omission is refused, not silent

- Status: accepted
- Revises: Decision, "emits no FK, ever" — the part that left a declared
  constraint out without a word
- Karr: k43 (core ADR 0060, conformance DDL list)

### Why

The decision stands that ClickHouse cannot build foreign keys or unique
constraints. What it got wrong is what the driver does with a declaration that
asks for one. Leaving it out silently makes a table that passes for one that
holds the constraint; the shared conformance list (core ADR 0060) calls that
falsifying, and the maintainer's decision of 2026-10-26 is that a case demanding
what ClickHouse lacks is a refusal, thrown before the first statement, naming
table and column.

### Decision

`DBIO::ClickHouse::DDL->install_ddl` throws, before it renders or executes
anything, for each of:

- a unique constraint other than the primary key;
- a relationship that is a foreign key constraint
  (`is_foreign_key_constraint` true, which is the default of `belongs_to`);
- an auto-increment column other than `uuid` and a sized `bit` (ClickHouse has
  neither identity columns nor a BIT type; `uuid` keeps `generateUUIDv4()`).

A table name qualified with a database (`other.t`) is not refused any more:
it is split and the table is created in that database, which must exist. The
Deploy refuses a missing database before the first statement, naming table and
database; only a name that names nothing (`a.b.c`, `.t`, `db.`) is refused.

All offenders of all tables are named in one exception, with table, its columns and a pointer
to the ClickHouse documentation. The way out is explicit: `ReplacingMergeTree`
for deduplication, `is_foreign_key_constraint => 0` on a relationship that is
only for joins, prefetch and `find`. The Diff inherits the refusal through the
scratch-database deploy. No topological sort and no FK/unique state in
introspection follow as before.

### Consequences

- A schema with a default `belongs_to` no longer installs until the relationship
  is declared `is_foreign_key_constraint => 0`: a behaviour change for existing
  users, deliberate, announced in `Changes`.
- Referential integrity stays the application's job; the driver now says so
  instead of implying otherwise.
