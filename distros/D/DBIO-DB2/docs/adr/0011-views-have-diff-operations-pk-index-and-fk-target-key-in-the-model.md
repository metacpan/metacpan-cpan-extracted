# ADR 0011 — Views get diff operations; the primary key's index and an FK's target key are in the model

- Status: accepted
- Date: 2026-10-25
- Tags: diff, introspect, views, index, foreign-keys

Implemented with karr k45. Decided by the maintainer (via the hub, 2026-10-25).

## Context

Three places where the model said less than the catalog, or the diff did less than
the model allowed:

1. **Views.** `Introspect::Tables` put a view into `tables` with `kind => 'view'`
   and nothing else. The diff could not write `CREATE VIEW` or `DROP VIEW`, so
   karr k36 made `Diff::Table` and `Diff::Column` refuse (die, naming the view)
   whenever a view was missing, surplus or differed in its columns. Any schema with
   a view whose live state was not exactly the declared one made `$deploy->diff`
   and `upgrade` unusable. dbio-mysql and dbio-sqlite have view operations.
2. **The index behind the primary key** lives in schema `SYSIBM`
   (`UNIQUERULE = 'P'`), under a server-chosen name. `Introspect::Indexes` filtered
   on the table's schema, never saw it, and its POD promise (`origin => 'pk'`) was
   dead code (karr k53).
3. **A foreign key onto a `UNIQUE` constraint.** `Introspect::ForeignKeys` took
   `to_columns` from the primary key of the parent table, so an FK onto a
   `UNIQUE` constraint reported the wrong columns (ADR 0009 listed this as not
   built).

## Decision

1. `Introspect::Tables` reads `SYSCAT.VIEWS.TEXT` and puts `view_definition` into
   the entry of a view: the text after the view's name (`AS SELECT ...`, with the
   column list in front when the view has one), the name and its schema cut off,
   the closing `;` and whitespace trimmed. `TEXT` holds the `CREATE VIEW` statement
   as it was written (measured: `CREATE VIEW "v" AS SELECT ...`, or
   `CREATE VIEW SCHEMA."v" (x, y) AS ...`), so the live view and the view of the
   compare schema (ADR 0006: the name is qualified by `_split_qualify_ddl`, the
   body resolves through `CURRENT SCHEMA`) compare by what they read.
2. `DBIO::DB2::Diff::View` writes `CREATE VIEW "name" <definition>;` and
   `DROP VIEW "name";`. A changed definition (whitespace set aside, letters as
   written) is a `drop` marked `replaced` followed by a `create`. A model without a
   definition on either side counts as unchanged; a `create` without one throws.
   `DBIO::DB2::Diff` puts all view drops at the head and all view creates at the end.
3. A view is no table: `Diff::Table` and `Diff::Column` leave every entry of kind
   `view` alone. The k36 refusals are gone and replaced by the view operations.
   A name that is a table on one side and a view on the other is a `DROP TABLE` (or
   a `CREATE TABLE` the other way) plus the view operation.
4. `Introspect::Indexes` reads the `SYSIBM` index of a primary key of the table
   (`UNIQUERULE = 'P'`, `TABSCHEMA` the introspected schema) and puts it into the
   model with `origin => 'pk'`, `is_unique` 1 and the primary key's columns. An index
   is identified by schema and name internally, since the two schemas share
   `SQL...` names in principle. `Diff::Index` skips an index with `origin 'pk'` on
   both sides (no `CREATE INDEX` for the target's, no `DROP INDEX` for the source's):
   it is the primary key, `CREATE TABLE` carries it, and its name differs between the
   live schema and the compare schema. `table_uniq_info` already left `origin 'pk'`
   out. The index behind a `UNIQUE` constraint stays out of the model (ADR 0009).
5. `Introspect::ForeignKeys` resolves `to_columns` through
   `SYSCAT.REFERENCES.REFKEYNAME`: `SYSCAT.KEYCOLUSE` with `constname = refkeyname`
   and the parent's `tabschema`/`tabname`, in `COLSEQ` order. That is the primary key
   or the `UNIQUE` constraint the FK references.

## Consequences

- `upgrade` and `diff` no longer die for a view. A view that reads another view
  being created in the same pass may be created before the one it reads: views are
  ordered by name (drops in reverse), not by what they read. A reader of a view
  that is replaced is not replaced with it. Not built; dbio-mysql orders and
  folds by reading the definitions (its karr k110, k113). *(Built: see the Addendum of 2026-10-25.)*
- `Diff::Column` makes no operation for a view's columns: they follow the
  definition.
- A model hand-built without `origin` for an index is unchanged in behaviour.
- A view body that qualifies its tables with the live schema name is compared
  as written (ADR 0006): live and compare views of it differ in nothing, and the
  body keeps pointing at the live schema.
- ADR 0009's "not built: an FK onto a unique constraint" is built for the
  introspection: the model's `to_columns` are the referenced key's columns.

## Addendum 2026-10-25 — views in the order of what they read (karr k54)

The "Not built" of the Consequences is built, as in dbio-mysql (its karr k110, k113),
by hub decision of karr k54:

- `DBIO::DB2::DDL::view_reads` reads a view definition for the names it reads as a
  table or view (after `FROM`, `JOIN` and the comma of a `FROM` list, in subqueries and
  derived tables too); `order_views` orders a set of definitions, a view after the views
  it reads, otherwise by name. A name is taken as the catalog holds it: `"x"` as written,
  an unquoted name upper-case (Db2 folds it so); a read matches a view of the set by
  that spelling, else by case folded when exactly one view has it. A schema qualifier is
  dropped.
- `install_ddl` writes its `CREATE VIEW` statements in that order, `Diff::View` creates
  in it and drops in the reverse. A view that reads a replaced view, directly or through
  other views, is replaced with it (dropped before, created after; its `drop` is marked
  `replaced`), so the server checks it against the new definition and a reader that no
  longer fits fails loudly in the apply. Views that read each other in a cycle are
  refused with a `DBIO::Exception` naming them, before any operation is returned.
  `Diff` keeps the drops at the head and the creates at the end.
- Not recognised, as in mysql: a view of another schema (the qualifier is dropped), a
  CTE named like a view.
- Tests: `t/74-diff-view-order.t` (offline), `t/75-diff-view-order-live.t`.

## Addendum 2026-10-25 — common table expressions and schema qualifiers (karr k55)

The "Not recognised" of the previous addendum is built, by hub decision of karr k55
(dbio-mysql does not do it; this is Db2's own):

- A name a `WITH` clause defines is no view: a `FROM a` that means a CTE is not a
  dependency even where a view `a` exists. A CTE name counts from its own definition on
  (so a recursive one reads itself), in the select of the `WITH` and everything nested in
  it; the reads inside the bodies count as any others. `WITH UR` and `WITH CHECK OPTION`
  are no CTE. A `WITH` that starts like a CTE but cannot be read is refused with a
  `DBIO::Exception`.
- A read qualified with a schema is judged against the schema the views are created in.
  Interface: `order_views(\%defs, $schema)` and `view_dependencies(\@set, $name, $def,
  $schema)` take it as an optional last argument, `view_reads($def, $schema)` drops reads
  of another schema, `install_ddl($schema, $view_schema)` passes it on. The qualifier
  is compared as the catalog holds it (unquoted upper-case, quoted as written): equal is
  a dependency, another schema is none. `Diff::View` takes the schema from the source
  (live) model, whose entries carry it; `Deploy` hands `install_ddl` the connection's
  `CURRENT SCHEMA`.
- Where the schema is not known, a qualified read of a name that is a view of the set is
  undecidable and is refused with a `DBIO::Exception` naming view and read, before any
  statement or operation: not guessed either way (dropping the qualifier orders by a
  view that may be another; keeping it may miss a real dependency). A qualified read of a
  name that is no view of the set is no dependency and no problem. So `install_ddl`
  called by hand without the schema and without a connection refuses `FROM DB2INST1.v` for
  a view `v` of the set. The refusal is wanted (loud instead of silently mis-ordered; no
  protection for the old hand-call behaviour); its exception is the connection: see below.
- Maintainer decision (karr k55): `install_ddl($schema)` without an explicit view schema
  determines the target schema itself, as the `CURRENT SCHEMA` of the schema object's
  connection (`DBIO::DB2::DDL::current_schema($dbh)`, the same read `Deploy` uses; Deploy
  delegates to it, so there is one way). A qualifier equal to it is resolved -- a dependency,
  as unqualified; any other qualifier stays a foreign schema, no dependency. A class, a
  storage that cannot connect or a handle that gives no answer leave the schema unknown, and
  the refusal stands. An explicit second argument wins and the connection is not asked.
- Unchanged: a body is compared and run as written (ADR 0006), so a qualifier naming the
  live schema in a view of the compare schema still reads the live object.
- Tests: `t/74-diff-view-order.t`, `t/81-view-order-cte-schema-live.t`.
