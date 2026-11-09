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
`-- rebuild required` comment instead of performing the dance (karr k2, k9).
That was safe but incomplete: such upgrades silently did nothing. Implementing
a real rebuild had two real hazards (karr k9):

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

After applying a diff that contained a rebuild, `DBIO::SQLite::Deploy::_execute_diff`
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
  introspect-model scope and are not yet handled (noted in karr k9).

## Amendment (2026-10-07)

The trigger above -- "any `alter` op" -- gains a second arm (karr k64). A
table is also rebuilt when the target **adds** a column whose declaration
`ALTER TABLE ... ADD COLUMN` cannot express.

Until then an added column was written from the introspected fields (type,
`NOT NULL`, `DEFAULT`), which dropped `REFERENCES` / `ON DELETE`, `CHECK`,
`COLLATE` and `UNIQUE` without a word; the next diff reported no change,
because it compares those same fields. `DBIO::SQLite::Diff::Column` now reads
the column's declaration out of the target's captured `CREATE TABLE` statement
(`_declarations`) and `as_sql` emits it as written. That covers everything
SQLite accepts in an `ADD COLUMN`. For the rest `Diff::Column::diff` sets
`needs_rebuild` on the `add` op, and `DBIO::SQLite::Diff::_build_operations`
treats such an op like an `alter`:

- the declaration carries `UNIQUE` or `PRIMARY KEY` -- SQLite refuses both in
  an `ADD COLUMN`, for an empty table too;
- a table constraint names the column (`PRIMARY KEY (...)`, `UNIQUE (...)`,
  `CHECK (...)`, the column list of a `FOREIGN KEY (...)`). SQLite has no
  statement that adds a table constraint, and this is the form
  `DBIO::SQLite::DDL::install_ddl` writes every foreign key and every unique
  constraint in, so it is the case an upgrade from result classes meets;
- the declaration cannot be found in the statement. The field-built form is
  the one known to be lossy, so an unreadable statement leads to the rebuild,
  never back to it.

As before, all of this applies only where the target model has the `CREATE
TABLE` text. Without it (compiled-model path) the added column is still
written from its fields.

Deliberately **not** a trigger (superseded in part by the amendment of
2026-10-09, which makes the non-constant default one): what SQLite refuses
only for a table that holds rows. Measured on libsqlite 3.51.1 these are a `NOT NULL` column without
a default, a non-constant default, a `REFERENCES` column with a non-`NULL`
default while `foreign_keys` is on, and a `STORED` generated column -- each is
accepted for an empty table. A diff of two models does not know whether the
live table has rows, so these stay `ADD COLUMN` and fail at SQLite for a
populated table. Whether they should rebuild instead is open (karr k65;
decided for the non-constant default in the amendment of 2026-10-09).

Consequence to weigh: more upgrades now go through the rebuild, so its known
limits are reached more often. A trigger on the rebuilt table is dropped with
it, and a view naming the table makes the final `RENAME` fail after the
`DROP` (`error in view ...: no such table`), leaving the table under its
`__dbio_rebuild` name. Both predate this amendment (see Consequences) and are
not addressed by it.

## Amendment (2026-10-08)

The last paragraph of the Decision -- without the `CREATE TABLE` text "the
per-column ops stand and render their explanatory comment" -- no longer holds
(karr k73). Such a change is now **refused**: `DBIO::SQLite::Diff::Column::as_sql`
throws, with a message naming the table, the column, what changed (type,
`NOT NULL`, default, old and new) and the reason -- SQLite has no ALTER COLUMN
and the target model holds no `CREATE TABLE` statement to rebuild the table
from. The same goes for an `add` op with `needs_rebuild` that is rendered on
its own; `DBIO::SQLite::Diff` never does that, it rebuilds.

The comment was no safe answer in either of its two forms. The `alter` one
carried a semicolon, core's `_split_statements` cut it there, and the rest of
the line reached SQLite as a statement: `near "rebuild": syntax error`, after
every statement before it had run. The `add` one had no semicolon and was
dropped by `DBIO::Deploy::Base::_execute_ddl` as intended -- so a diff that
reported changes applied none of this one and told nobody. The Context of this
ADR already names that as the defect of the first driver ("such upgrades
silently did nothing"); the fallback had kept it for the models without a
statement.

It follows the line the maintainer set for every driver: a diff that cannot
carry out a change safely refuses loudly, naming the table and the reason.
Doing nothing silently, or producing invalid SQL, is never acceptable.

What does not change: when a table is rebuilt. Not rebuilding from the column
model remains the decision -- that rebuild is the lossy one -- the refusal
only replaces what is said instead.

Consequences:

- `DBIO::SQLite::Diff::as_sql` renders every op, so one refused op refuses the
  whole diff. `DBIO::Deploy::Base::apply` renders the diff before it runs the
  first statement, and so does `DBIO::SQLite::Deploy::_check_before_apply`, so
  `apply` throws with the database untouched, where it used to stop half way.
- `has_changes` and `summary` still answer for such a diff; a caller can print
  what it contains.
- A caller on the compiled-model path that changes a column's type,
  nullability or default now gets an exception where it got a script with a
  comment in it. The way to apply such a change is the introspect path
  (`DBIO::SQLite::Deploy::diff`), which has the statement.

## Amendment (2026-10-08) -- what hangs on the table, and the connection

The rebuild of the Decision knew the table and nothing else: its statement and
a list of column names. Three defects came from that one cause (karr k69, k70,
k71), and the Consequences line "Triggers and views referencing a rebuilt
table ... are not yet handled" is hereby answered, as is the last paragraph of
the 2026-10-07 amendment.

**Triggers are in the model, and the rebuild carries them.**
`DBIO::SQLite::Introspect::Triggers` reads them from `sqlite_master` into a
`triggers` section, shaped like `indexes`: by owning table or view, then by
name, each with its `CREATE TRIGGER` statement. `DBIO::SQLite::Diff`
(`_build_operations`) hands the `Rebuild` op the statements of the **source**
table's triggers, and the op runs them again once the new table has the name.
Triggers are carried, never compared: `DBIO::SQLite::DDL::install_ddl` cannot
declare one, so a target deployed from result classes has none, and a
comparison would drop every trigger of the live database.

**Views survive through `PRAGMA legacy_alter_table=ON`.** A view that selects
from the table is untouched by the `DROP`, but since libsqlite 3.25 a
`RENAME` reads the whole schema to rewrite references to the table, and at
that moment the view names a table that is gone -- the rename failed, after
the drop. Under the legacy setting the rename changes the table's name and
looks at nothing else. That is all the rebuild needs: views, and triggers of
other tables that name the table, name it by the name it has again
afterwards. The alternative is SQLite's own recipe, which drops the dependent
views and creates them again. It was not taken: it has to find those views
first, which means reading every view's body, and dropping a view drops its
`INSTEAD OF` triggers, which would then have to be carried too -- all to
rewrite statements that do not change.

**The rebuild is one unit.** Between `SAVEPOINT dbio_rebuild` and `RELEASE
dbio_rebuild` stand the create, the copy, the drop, the rename and the
triggers; rolled back to the savepoint the original table is there again with
its rows, indexes and triggers. A savepoint and not `BEGIN`, so that it nests
in a transaction the caller has open. The two pragmas stand outside:
`PRAGMA foreign_keys` is ignored while a savepoint is open, and no rollback
undoes either of them.

**The connection belongs to `DBIO::SQLite::Deploy::_execute_diff`.** The op is
text and cannot know what the connection had, so it ends in a fixed
`legacy_alter_table=OFF` and `foreign_keys=ON` -- which switched foreign keys
on for a connection that had them off (k71) -- and after a failure its last
statements never run. For a diff with a rebuild, the hook reads both pragmas
first and puts them back afterwards, on success and on failure; on failure it
rolls the open savepoint back before that and throws the original error on.
`PRAGMA foreign_key_check` runs only if foreign keys were enforced before:
with enforcement off a dangling row is the caller's declared state, not a
finding of this upgrade.

**Generated columns are not copied.** A column that is generated in the
target (`hidden` 2 or 3 in `PRAGMA table_xinfo`) is left out of the copy list;
SQLite refuses the `INSERT` otherwise (k70). One that was generated and is
plain now is copied.

**A diff hands out statements.** `DBIO::SQLite::Diff::Rebuild::statements`
and `DBIO::SQLite::Diff::statements` return them one by one, and `as_sql` is
that list joined. A trigger's statement has semicolons inside it, so the text
cannot be cut back into statements; `_execute_diff` runs the list. It still goes
through `DBIO::Deploy::Base::_execute_ddl` as one batch, except that a
statement with an inner semicolon is handed to the handle whole -- core's
`_split_statements` cuts at every semicolon (core karr k326). The exception
goes when the splitter reads SQLite's statements.

Consequences:

- An upgrade whose rebuild fails leaves that table as it was and the
  connection as it was, and can be run again. The diff as a whole is still
  not atomic: what ran before the failing op stays applied.
- With `legacy_alter_table` the rename no longer reads the schema. A view or
  trigger that names a column the rebuild removes is not refused at the
  upgrade: the rename goes through and the view fails when it is used (`no
  such column`), and SQLite accepts a carried trigger like that when it is
  created.
- `as_sql` of a rebuild is a complete script, and whoever runs it by other
  means than `apply` (and so `_execute_diff`) gets neither the rollback nor
  the restored pragmas.
- A `TEMP` trigger on a rebuilt table is not in `sqlite_master`, hence not in
  the model, and is lost with the `DROP`.
- Inside a caller's transaction `PRAGMA foreign_keys=OFF` is ignored, as
  before; rebuilding a table that others reference then fails at the `DROP`
  with foreign keys on -- now without leaving anything behind.

## Amendment (2026-10-08) -- what a table declares, and what a name is

Until here `DBIO::SQLite::Diff` decided from two things: whether a name is
there, and -- for a name on both sides -- whether its columns differ in type,
`NOT NULL` or default. Two defects came from that one cause (karr k72, k67).

**The rebuild's trigger gains five arms.** A plain table that both models
have, and whose target entry has its `CREATE TABLE` statement, is rebuilt when
any of these differ (`_table_changes` in `DBIO::SQLite::Diff`):

- a. the **primary key** -- its columns in the order of the key
  (`pk_position`). From the model: `PRAGMA table_xinfo` reports it.
- b. the **`UNIQUE` constraints** -- the set of column lists of the automatic
  indexes of origin `u`. From the model: `PRAGMA index_list` reports a
  constraint that way, written on the column or on the table alike, and one
  index for a constraint declared twice.
- c. the **foreign keys** -- the set of signatures: columns, target table,
  target columns, `ON UPDATE`, `ON DELETE`, names and actions in any letter
  case. From the model (`PRAGMA foreign_key_list`). A set, because a database
  deployed before karr k74 may hold one key twice and has its lines in a
  hash's order. A key of the target over a column the source lacks is left
  out: it arrives with the column, and the decision of the 2026-10-07
  amendment -- a column added with a column-level `REFERENCES` does not
  rebuild -- stands. A key of the source over a column the target drops
  counts.
- d. **`CHECK`, `COLLATE`, generated expressions**, where the target states
  them (below) -- per column both tables have, and the table's `CHECK`
  constraints. From the two statements, because
  no `PRAGMA` reports them; read by the reader the 2026-10-07 amendment
  introduced (`_declarations` in `DBIO::SQLite::Diff::Column`), extended. The
  statement text as a whole is not comparable -- SQLite splices it on `ADD
  COLUMN` / `DROP COLUMN` and the rebuild's `RENAME` quotes the name -- so
  only these clauses are compared: as written, whitespace and comments aside,
  framing keywords and collation names in any letter case, expressions token
  for token. That is conservative on purpose: a respelling rebuilds once and
  then matches, a real change is never missed. A statement the reader cannot
  follow is not skipped; the two statements are then compared whole, the name
  aside, and a difference rebuilds -- which ends it, since the live statement
  is the target's afterwards.
- e. **`WITHOUT ROWID` / `STRICT`** that the target has and the source has
  not -- the two fields of the table entry. `DBIO::SQLite::Introspect::Tables`
  now reads them with the lexer, behind the closing parenthesis of the column
  list (`_table_options`): the regular expressions it had missed `STRICT`
  beside `WITHOUT ROWID` in both orders and found `WITHOUT ROWID` in a string
  or a name.

The gate is the one of the Decision: no statement, no rebuild. A model without
one (`target_from_compiled`, built by hand) holds no indexes and no foreign
keys by construction, which says "not stated", not "none"; nothing of a--e is
compared for it. The reasons found are kept on the `Rebuild` op (`reasons`)
and shown by its `summary`; that is how the diff reports the change.

Deliberately **not** compared: `AUTOINCREMENT` (ADR 0004, karr k52 open),
`ON CONFLICT`, `DEFERRABLE`, constraint names, the order of columns.

**The target is the desired state, in what it states.** Arms a--c are
symmetric: a result class declares its key, its `UNIQUE` constraints and its
foreign keys (`set_primary_key`, `add_unique_constraint`, `belongs_to` and
`is_foreign_key_constraint`), so their absence in the target is a statement,
and a key or constraint only the live table has goes with the rebuild.

Arms d and e are not. No result class can declare a `CHECK`, a `COLLATE`, a
generated column, `WITHOUT ROWID` or `STRICT`, and the target of
`DBIO::SQLite::Deploy` is deployed from result classes: there "the target has
none" means "not stated", not "none wanted". These arms follow the
desired-state contract the family already has and the diff already follows for
a column's fields -- `DBIO::Diff::Compare::changed_fields`, core ADR 0019: a
field the target leaves unstated is not compared; stated and different is a
change; stated against missing is a change. So a column whose target has no
`CHECK`, no `COLLATE` or is not generated is not compared in that clause; the
table's `CHECK`s are not compared when the target has none, and are compared
set against set when it has some -- it has then stated all of them; and
`WITHOUT ROWID` / `STRICT` are a change only when the target has the option
and the source has not. A table made by hand with one of these, under a
schema that describes it, diffs to nothing -- which is what
`t/41-diff-pk-nullability-roundtrip.t` (karr k32) holds for a `WITHOUT ROWID`
table.

Whether a clause only the live table has should ever be removed is the same
family question as question 6 of core ADR 0060 ("a default that leaves the
declaration") and is not answered here. Triggers stay carried and never
compared, as in the previous amendment.

**A view is a view.** `Introspect::Tables` lists views and virtual tables
under `tables`; the model shape stays, and the diff sorts the entries by what
they are before any walk (`_by_kind`). A view is dropped by `DROP VIEW`,
created by its statement, replaced by both when its definition differs
(`DBIO::SQLite::Diff::View`; the name read however it is quoted, the rest
token for token), and never gets a column op, an index op or a rebuild. A
replaced view keeps its `INSTEAD OF` triggers: the create op carries the
source's statements, as the rebuild does. A **virtual table** is created and
dropped; one that both sides have and that differs, or that is a plain table
on the other side, is **refused** in the way of the first 2026-10-08
amendment (`DBIO::SQLite::Diff::Table`, action `refuse`): SQLite cannot alter
it and a rebuild would lose what its module stores. Refused the same way is a
view the target lists without its `CREATE VIEW` statement (a model built by
hand): `DBIO::SQLite::Diff::View::statements` throws, since a view cannot be
written from its columns and an empty statement would be dropped by the DDL
run without a word.

**The order of the ops** is fixed by what SQLite checks, measured on libsqlite
3.51.1: (1) `DROP VIEW`, (2) `DROP INDEX`, (3) table creates, drops and
refusals, (4) `ADD COLUMN`, (5) rebuilds with their indexes, (6) `CREATE
VIEW`, (7) `DROP COLUMN`, (8) `CREATE INDEX`. `ALTER TABLE ... DROP COLUMN`
reads the whole schema: any view that names something gone fails it, on
whichever table the column is (`error in view ...`), and so does an index
over the column (`error in index ... after drop column`). `CREATE TABLE`,
`DROP TABLE`, `ADD COLUMN` and `CREATE VIEW` check nothing beyond their own
object, and the rebuild renames under `legacy_alter_table`.

Consequences:

- More upgrades rebuild. An existing database whose tables differ from the
  schema in a key, a `UNIQUE`, a foreign key or its actions is rebuilt table
  by table on the next upgrade -- among them every database deployed before
  `install_ddl` wrote `ON DELETE` / `ON UPDATE` (karr k66) whose
  relationships declare one.
- A rebuild copies rows by `INSERT` into the new table, so a row the new
  `CHECK`, `UNIQUE` or `NOT NULL` forbids fails it; `apply` (through
  `_execute_diff`) rolls that rebuild back and throws.
- A view the schema does not declare is dropped by an upgrade, as an
  undeclared table already was.
- **What causes a rebuild is not what survives one.** A table that is
  rebuilt, for whichever reason, is created from the target's statement, so
  whatever the target does not state is gone afterwards -- also a hand-made
  `CHECK`, `COLLATE`, generated column, `WITHOUT ROWID` or `STRICT` that the
  comparison left alone. That has been so since the Decision of this ADR;
  arms d and e merely do not cause a rebuild for it.
- A live column that is generated while the target declares it plain is left
  as it is by arm d, like every other clause the target does not state.
- The diff compares a view's statement and does not read its body. A declared
  view that names a column the schema no longer has makes `Deploy->diff` die
  while the target model is built (`PRAGMA table_xinfo` on the view) when the
  name is written bare. Written in double quotes, SQLite reads the unresolved
  name as a string literal: the view is valid, returns that string, and the
  upgrade applies -- the same view a fresh install of that schema creates.

## Amendment (2026-10-09)

The second arm of the trigger grows a third reason (karr k65): the target adds
a column whose `DEFAULT` is not a constant.

`ALTER TABLE ... ADD COLUMN ... DEFAULT (datetime('now'))` is valid and runs on
an empty table; on a table that holds rows SQLite refuses it (`Cannot add a
column with non-constant default`). Refused alike: any parenthesised expression
(`(1+2)`, `('a' || 'b')`) and `CURRENT_TIME`, `CURRENT_DATE`,
`CURRENT_TIMESTAMP`. A diff of two models cannot know whether the live table has
rows, so the maintainer decided (2026-10-09, option b of k65): such a column
rebuilds the table. The rebuild copies the rows into the new table and SQLite
evaluates the default for each of them, so the column is filled.

`Diff::Column::_declarations` reads the column's `DEFAULT` out of the target
statement and sets `nonconstant`; `diff` turns that into `needs_rebuild` on the
`add` op, and `_build_operations` does the rest as for the other reasons. The
rule is deliberately plain: **any parenthesised expression** counts, and the
three `CURRENT_*` keywords. A literal -- number, string, `NULL`, `TRUE`,
`FALSE`, a signed number, and such a literal alone in parentheses
(`DEFAULT (NULL)`, which SQLite takes as constant) -- stays an `ADD COLUMN`.
Same gate as before: only where the target model has the `CREATE TABLE` text;
the compiled-model path still writes the `ADD COLUMN` from its fields.

Price: a table with no rows is rebuilt too, where an `ADD COLUMN` would have
sufficed, and with it every limit of the rebuild reached more often (the
consequence noted in the amendment of 2026-10-07 stands).

Still **not** a trigger, and failing at SQLite for a populated table: `NOT NULL`
without a default (a rebuild does not help, the copy fails the same way), a
`REFERENCES` column with a non-`NULL` default while `foreign_keys` is on, and a
`STORED` generated column.

## Amendment (2026-10-30) -- the hooks of core's `apply`, and lossy changes

`DBIO::SQLite::Deploy` has no `apply` and no `upgrade` of its own (core karr
k399, core ADR 0080). Both are inherited from `DBIO::Deploy::Base`, which
guards the diff (`allow_destructive`, `dry_run`) and calls two hooks:
`_check_before_apply` renders the statements and runs `_refuse_unfillable`;
`_execute_diff` runs them, with the pragma bracket, the rollback of a failed
rebuild and `PRAGMA foreign_key_check` described above. Order, messages and
rollback are unchanged.

A rebuild reports `lossy` when it drops a column or changes one in a way that
may alter a stored value, so it runs with `allow_destructive => 1` only. A
change of the type name is lossless for names of one type affinity (the copy
passes the value through the same affinity as the first insert) and lossy for
every other pair, unknown names included.

## Related

- karr k72 (what a table declares is compared), karr k67 (views and virtual
  tables are not tables), karr k66 (`ON DELETE` / `ON UPDATE` in the DDL),
  karr k74 (doubled foreign keys), karr k32 (the no-op upgrade of
  `t/41-diff-pk-nullability-roundtrip.t`), karr k52 (`AUTOINCREMENT` -- open)
- core ADR 0019 (desired-state diff ignores fields the target leaves
  unstated -- the contract of arms d and e), core ADR 0060 question 6 (a
  declaration that goes -- open)
- karr k69 (views and triggers around a rebuilt table, a failed rebuild left
  half way), karr k70 (generated columns in the copy), karr k71 (the bracket
  switched foreign keys on)
- karr k73 (a change the diff cannot carry out is refused, not commented)
- karr k64 (rebuild for added columns ADD COLUMN cannot express), karr k65
  (a non-constant default rebuilds -- amendment 2026-10-09; `NOT NULL` without
  a default stays an `ADD COLUMN`)
- ADR 0001 (native schema management)
- ADR 0002 (in-memory test-deploy-and-compare -- supplies the captured DDL)
- ADR 0004 (plain INTEGER PRIMARY KEY -- what the captured DDL preserves)
- karr k9 (rebuild implementation and its prerequisites)
