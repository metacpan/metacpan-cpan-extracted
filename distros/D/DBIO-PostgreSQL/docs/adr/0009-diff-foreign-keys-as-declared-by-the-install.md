# ADR 0009 — The diff compares foreign keys; the target is what the install declares

- Status: accepted
- Date: 2026-10-20
- Tags: diff, foreign-key, deploy, drivers

## Context

The install writes a FOREIGN KEY for a `belongs_to` of a class with
`pg_fk_constraints_from_rels` (on by default since 2026-10-21, switched off
per class with 0), with the `ON DELETE` and `ON UPDATE` it declares
(karr k127). The diff had no class for foreign keys: the target model of a
deploy is read from a temporary database the install built, so it holds them,
and nothing compared or wrote them. A table an upgrade created had no foreign
key, a changed action was "no changes", and a key the schema does not declare
stayed. The other drivers of the family have a foreign key diff class
(MySQL, Sybase, MSSQL, DB2, Firebird).

## Decision

`DBIO::PostgreSQL::Diff::ForeignKey` is a section of the diff (`foreign_keys`),
after the indexes: the primary key or unique constraint a foreign key points at
is created first, and the foreign key is dropped before the one it points at.

- **Compared in the form of the introspection** (columns, referenced schema and
  table, referenced columns, `on_delete`, `on_update`), not by core's
  `changed_fk_fields`, which compares canonical names and skips fields the
  target leaves undef. A difference is a drop plus a create under the name,
  the drop `replaced`.
- **The name is the target's.** The target model comes from the install, so
  its constraint name is the one the install chose (`<table>_<columns>_fkey`);
  the diff takes it from there and install and diff cannot disagree.
- **A key the schema does not declare is dropped**, and the summary says so
  (maintainer decision 2026-10-20). A target model without the `foreign_keys`
  section at all (a hand-built model, `target_from_compiled`, which has no
  relationships to read) declares nothing, and the section is not diffed.
- **A table the diff creates gets its keys** (the walk covers every table of
  the target); the keys of a table that is dropped go with the table
  (`DROP TABLE ... CASCADE`) and get no statement.
- **`foreign_keys_not_valid`**, an option of `DBIO::PostgreSQL::Deploy`
  (default off): the key is added `NOT VALID` on a table the database has, and
  a `VALIDATE CONSTRAINT` for each follows behind all of them. `apply` runs one
  transaction, so the lock is held until its end; the option moves the reading
  of the rows to a step of its own, which whoever wants the lock released
  between the two runs separately. A key left `NOT VALID` is
  validated by the next diff (`convalidated` is read, `VALIDATE CONSTRAINT`);
  rows that break it fail that upgrade until they are cleaned up.
- **`is_foreign_key_constraint => 0`** on a `belongs_to` writes no key for it
  (as MySQL and SQLite do for the same attribute); the k120 refusal for a
  relationship to a class not loaded or a table outside the deploy names it as
  a way out beside `pg_fk_constraints_from_rels(0)`.
- **A key of the database that points outside the deploy** is kept unless the
  target declares a key of the same name on the same table onto another table:
  that is a redefinition, dropped and created.
- **The action word is checked** where the install writes it: one of NO ACTION,
  RESTRICT, CASCADE, SET NULL, SET DEFAULT, in any case; another is refused
  naming the relationship.
- **Refusals over an index a foreign key stands on stay** (`referenced_by` in
  `Diff::Index`, karr k139). A replaced drop of an index or constraint stays in
  the first half, ahead of the foreign key's drop; a layout the section order
  cannot express is a migration by hand in two steps.

- **Validity, MATCH and the column list of the action** (karr k140). The
  introspection reads `pg_constraint.convalidated` (`is_valid`),
  `confmatchtype` (`match`: SIMPLE, FULL) and, from PostgreSQL 15,
  `confdelsetcols` (`on_delete_columns`, for `ON DELETE SET NULL|SET DEFAULT
  (cols)`). MATCH and the column list are part of a key's definition: another
  value is the drop and create of the pair, like another action. Validity is
  not: a key the database holds `NOT VALID` while the target's is valid
  (a model that says nothing holds a valid one; the target is what the install
  built) gets `ALTER TABLE ... VALIDATE CONSTRAINT`, no drop and no create.
  With `foreign_keys_not_valid` this adds nothing: the option marks creates
  only, and the validate of a create is in the same plan. The install cannot
  declare MATCH FULL or a column list (`belongs_to` has no attribute for them);
  a key declared by `pg_extra_ddl` that has them is read back from the temp
  database, and the diff writes them in the create (`MATCH FULL` ahead of the
  actions, `ON DELETE SET NULL (cols)`), so install and diff still write one
  constraint. A create of a key on a server before 15 never carries a column
  list.

- **Keys into a table outside the deploy are kept** (maintainer decision
  2026-10-21). A key the database has whose referenced table is in neither
  model (another schema outside `pg_schemas`) is not the deploy's: the temp
  database the target is built in lacks that table, so the target cannot
  declare the key, and dropping it would break what the deploy does not own.
  It is neither compared nor dropped (the target's key of the same name is not
  compared with it), and the summary names it,
  `=fk: NAME (on TABLE -> REFERENCED) -- kept (target outside the deploy)`. The
  line is no operation: no statement, not in `operations`, no `has_changes`.
  A table only one model has is inside the deploy (created or dropped), so a
  key into it is compared and dropped like any other; an undeclared key
  between two deployed tables is still dropped.

## Not decided here

`DEFERRABLE` is read (`is_deferrable`) and written by nothing; the diff neither
writes nor compares it. A known gap, kept visible in the POD of the class and
in `Changes`.

## Consequences

- An upgrade of a database whose foreign keys were made outside DBIO drops them
  unless the schema declares them. The summary names each.
- Install and diff write one constraint for one declaration.
