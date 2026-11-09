# ADR 0009 — A source's unique constraints are named UNIQUE constraints, carried in the model's `unique_constraints` section

- Status: proposed
- Date: 2026-10-22
- Tags: ddl, introspect, diff, unique

Implemented with karr k39; the maintainer decided the emitted form (named
constraint in `CREATE TABLE`, refusal over a nullable column). The model form
below is the implementer's choice and waits for confirmation.

## Context

`DBIO::DB2::DDL::install_ddl` never read the `unique_constraints` of a source:
an `add_unique_constraint` in a result class was silently not deployed. The
follow-up diff was empty, so nothing noticed. The other drivers (PostgreSQL,
MySQL, MSSQL, SQLite) emit them.

Measured against Db2 12.1.5 (2026-10-05 and 2026-10-22):

- `CONSTRAINT "uq_ab" UNIQUE ("b","a")` in `CREATE TABLE`, and
  `ALTER TABLE ... ADD CONSTRAINT`, both give a row of type `U` in
  `SYSCAT.TABCONST`, the columns in `SYSCAT.KEYCOLUSE` (`COLSEQ` 1 = `b`,
  2 = `a`), and an index of the same name in the table's schema
  (`SYSCAT.INDEXES`, `UNIQUERULE` `U`, `SYSTEM_REQUIRED` 1).
- `ALTER TABLE ... DROP UNIQUE "uq_ab"` removes the constraint and the index.
- The index behind a primary key is in `SYSIBM` and never seen by the
  introspector (karr k53); the one behind a unique constraint is in the table's
  schema and was seen as an ordinary unique index, which the diff wanted to
  `DROP INDEX` once `install_ddl` emitted the constraint.
- `UNIQUE` over a nullable column is refused by the server (`SQL0542N`).

## Decision

1. `install_ddl` emits each `unique_constraints` entry of a source (the
   `primary` one excepted) as `CONSTRAINT "<name>" UNIQUE ("<col>", ...)` inside
   `CREATE TABLE`, after the primary key and before the foreign keys, in name
   order. The name is the source's own constraint name. Every identifier goes
   through `_db2_quote_ident`. `DBIO::DB2::Diff::Table` (`create`) renders the
   same clause from the model through `_unique_constraint_clause`, the single
   place the shape is written.
2. A constraint over a nullable column is refused when rendering (`croak`, naming
   constraint, table and column). A column without `is_nullable` is `NOT NULL`
   (core ADR 0043), as everywhere in `install_ddl`. The `Diff::Table` path
   refuses on `not_null` of the catalog-shaped column.
3. The model carries constraints in a new section `unique_constraints`
   (`{ $table => [ [ $name, \@columns ], ... ] }`), which is the optional section
   of the `DBIO::Introspect::Base` contract, no new shape. Every table has an
   entry. `DBIO::DB2::Introspect::UniqueConstraints` reads it from
   `SYSCAT.TABCONST` type `U` and `SYSCAT.KEYCOLUSE`.
4. `DBIO::DB2::Introspect::Indexes` leaves out an index whose name is that of a
   type `U` constraint of its table: the index is the constraint. Without that,
   a constraint dropped from the schema would be a `DROP UNIQUE` and a
   `DROP INDEX` of an index already gone.
5. The base's `table_uniq_info` takes the section as the whole answer, which
   would lose the unique indexes of `db2_indexes`. `DBIO::DB2::Introspect`
   overrides it: constraints first, then the unique non-primary indexes.
6. `DBIO::DB2::Diff::UniqueConstraint` handles tables present in both models:
   `ALTER TABLE ADD CONSTRAINT ... UNIQUE`, `ALTER TABLE DROP UNIQUE`, and a
   changed column list as drop-then-add. It runs after the index pass and before
   the foreign keys. Constraints of a new table are inline; those of a dropped
   table go with it.

## Consequences

- A model without the section (older, or hand-built) diffs as "no constraints".
- Constraint names must be unique within the schema in practice, because Db2
  names the backing index after them and index names are unique per schema. Two
  tables with a constraint of the same name were not measured.
- Not built: a `FOREIGN KEY` that references a unique constraint (the
  introspector resolves the parent's primary key only); a unique constraint
  over nullable columns via `EXCLUDE NULL KEYS` (that is an index, `db2_indexes`).
