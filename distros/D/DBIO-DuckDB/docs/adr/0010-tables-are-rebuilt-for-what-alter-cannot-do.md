# ADR 0010 — Tables are rebuilt for what ALTER TABLE cannot do

- Status: accepted
- Date: 2026-10-26

## Context

Four changes to a table that exists have no `ALTER TABLE` in DuckDB (libduckdb
1.5.3, [alter_table](https://duckdb.org/docs/stable/sql/statements/alter_table)):

- a column dropped while an index or a `UNIQUE` constraint stands on a later
  column, or on the column itself ("an index depends on a column after it");
- a `UNIQUE` constraint that goes;
- a foreign key added or dropped;
- a `UNIQUE` constraint added that a foreign key then points to. The diff added
  a `UNIQUE` to an existing table as `CREATE UNIQUE INDEX`, and DuckDB takes a
  foreign key to a `PRIMARY KEY` or `UNIQUE` constraint only: "referenced table
  does not have a primary key or unique constraint on the columns".

The diff refused all of them before the first statement (ADR 0001 addendum
2026-10-25, karr k49). The shared case list of core (ADR 0060) holds them as
`diff-column-dropped-with-index`, `diff-fk-dropped` and
`diff-fk-added-to-new-unique`; the maintainer decided (2026-10-26) that the
driver does them, as dbio-sqlite does (its ADR 0003, karr k72).

## Decision

1. `DBIO::DuckDB::Diff::rebuild_reasons` names the tables of both models that
   need it, with the reasons above. For such a table the column operations and
   the index operations of the diff are replaced by one
   `DBIO::DuckDB::Diff::Rebuild` and the creation of every index the target
   declares for it. The `UNIQUE` constraints and foreign keys are in the new
   table's `CREATE TABLE`, and an added `UNIQUE` that a foreign key needs is a
   constraint, not an index.
2. The rebuild is: `CREATE TABLE t__dbio_rebuild` (in the table's schema) with
   the target definition, `INSERT ... SELECT` of the columns both tables have,
   `DROP TABLE t`, `ALTER TABLE ... RENAME TO t`, then the indexes. No
   statement of its own brackets it: `DBIO::DuckDB::Deploy::apply` already runs
   the diff in one transaction (`_use_transactional_ddl`, ADR 0005), so a copy
   a new key or `NOT NULL` refuses takes everything back. Measured: `INSERT`,
   `DROP`, `RENAME` and `CREATE INDEX` on the new table in one transaction work.
   A column the new table has and the old lacks gets its default.
3. Creates and rebuilds come in one order, by the target's foreign keys, the
   table a key points to first, whether it is created or rebuilt (a key to a
   rebuilt table needs its new constraint; a rebuilt table's key to a new
   table needs the table). Table drops are not part of that order.
4. Refused before the first statement, by `Deploy->diff` and `apply`, naming the
   tables and the reason of the rebuild:
   - a table another table has a foreign key to. Measured: `DROP TABLE` fails
     with "Could not drop the table because this table is main key table of the
     table ...", in a transaction as well. A referencing table the diff drops
     does not count.
   - a table that points to itself in the target. Measured: the new table's key
     keeps pointing to the temporary name after the rename ("Table with name
     ..__dbio_rebuild does not exist"), and one `INSERT ... SELECT` of a
     self-referencing table fails on the order of its own rows.
5. `NOT NULL` without a default for rows already there, a `NULL` where
   `NOT NULL` is wanted and duplicates for a new `UNIQUE` are refused as for the
   `ALTER` path (they look at the column operations the rebuild replaced,
   kept as `column_ops`).
6. `CASCADE`, `SET NULL` and `SET DEFAULT` stay refused (ADR 0001): the target
   is built from the install DDL, which refuses them.

## Consequences

- Views, sequences and the other tables' rows are untouched. A view over a
  rebuilt table survives (DuckDB records no dependency of a view on a table).
- Rebuild triggers are the four above only; a type change on an indexed column
  is still the `ALTER` that DuckDB refuses (not touched).
- The statements of `Diff::as_sql` are a script only inside a transaction;
  run one by one, a failing copy leaves the temporary table behind.
