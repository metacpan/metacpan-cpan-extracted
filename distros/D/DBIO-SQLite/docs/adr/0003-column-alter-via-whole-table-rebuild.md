# 3. Column ALTER via whole-table rebuild

Date: 2026-06-20

## Status

Accepted

## Context

SQLite's `ALTER TABLE` cannot change a column's type, nullability or default
in place. The only supported way to apply such a change is the rebuild dance
documented by SQLite: create a new table with the desired shape under a
temporary name, copy the surviving data across, drop the original, and rename
the new table into place.

The initial driver rendered every type/nullability/default change as an inert
`-- rebuild required` comment instead of performing the dance (karr #2, #9).
That was safe but incomplete: such upgrades silently did nothing. Implementing
a real rebuild had two real hazards (karr #9):

- reconstructing the table from the column model is lossy -- it can drop the
  PRIMARY KEY, inline foreign keys, `WITHOUT ROWID` / `STRICT` modifiers and
  column defaults that the model does not faithfully carry;
- dropping a table that other tables reference violates foreign keys unless FK
  enforcement is suspended for the operation, and dangling references must be
  re-checked afterwards.

## Decision

When a column diff for a table contains any `alter` op *and* the target
table's original `CREATE TABLE` text is available (the introspect path
provides it via `sqlite_master`; the compiled-model path does not),
`DBIO::SQLite::Diff` replaces that table's per-column ops with a single
`DBIO::SQLite::Diff::Rebuild` op and re-emits the table's explicit
(non-auto) indexes afterwards.

The rebuild (`DBIO::SQLite::Diff::Rebuild::as_sql`):

- builds the new table from the *captured* target `CREATE TABLE` statement
  with only the leading table-name token swapped for a `__dbio_rebuild`
  temporary name -- reusing the captured DDL verbatim keeps PK,
  AUTOINCREMENT, inline FKs, `WITHOUT ROWID`, `STRICT` and defaults exactly as
  declared;
- copies only the columns present in both old and new tables;
- brackets itself with `PRAGMA foreign_keys=OFF` ... `PRAGMA foreign_keys=ON`,
  which is honoured because `DBIO::Deploy::Base::_execute_ddl` runs each
  statement one at a time with autocommit on.

After applying a diff that contained a rebuild, `DBIO::SQLite::Deploy::apply`
runs `PRAGMA foreign_key_check` and throws if any dangling references remain.

When the original `CREATE TABLE` text is not available (compiled-model path),
the per-column ops stand and render their explanatory comment rather than risk
a lossy rebuild.

## Consequences

- Type / nullability / default changes are actually applied, with table data
  and structure preserved, instead of being silently skipped.
- Faithfulness depends on having the captured `sqlite_master` DDL; this is why
  the rebuild is enabled only on the introspect path (see ADR 0002, which
  produces that captured text on both sides of the diff).
- Indexes are dropped with the rebuilt table and must be -- and are --
  re-created from the target model afterwards.
- Cross-table FK integrity is enforced after the fact via `foreign_key_check`,
  not prevented during the OFF window.
- Triggers and views referencing a rebuilt table are out of the current
  introspect-model scope and are not yet handled (noted in karr #9).

## Related

- ADR 0001 (native schema management)
- ADR 0002 (in-memory test-deploy-and-compare -- supplies the captured DDL)
- ADR 0004 (plain INTEGER PRIMARY KEY -- what the captured DDL preserves)
- karr #9 (rebuild implementation and its prerequisites)
