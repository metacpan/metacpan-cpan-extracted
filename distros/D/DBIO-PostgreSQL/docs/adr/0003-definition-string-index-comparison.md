# ADR 0003 — Definition-string index comparison instead of field-by-field

- Status: accepted
- Date: 2026-06-20
- Tags: diff, index, introspect, drivers

## Context

Core's diff layer (core ADR 0007) supplies `DBIO::Diff::Compare`, the
engine-agnostic comparison kernel, including `changed_index_fields` — the
generic way to detect an index change by comparing structured fields (columns,
uniqueness, access method). The expectation is that each driver's `Diff::Index`
reuses that field comparator.

That contract is too coarse for PostgreSQL. A PostgreSQL index can differ along
axes the generic field set does not model: a partial-index `WHERE` predicate, an
expression index (`lower(name)`), storage parameters (`WITH (lists = 100)` for
ivfflat), the access method, `INCLUDE` columns, opclasses, collations. Two
indexes can compare "equal" on the generic fields while being materially
different in PostgreSQL. PostgreSQL already hands us a canonical, fully-rendered
form of every index — `pg_get_indexdef` — that captures all of these exactly.

## Decision

`DBIO::PostgreSQL::Diff::Index` overrides core's field-by-field contract and
compares indexes by **full definition-string equality**, deliberately *not*
using `DBIO::Diff::Compare`'s `changed_index_fields`.

- Index identity is by name. When an index exists on both sides, the comparison
  is a plain string compare of the `pg_get_indexdef` definition:
  `$src_def ne $tgt_def` (`Diff/Index.pm`, `diff`).
- Any difference emits a **drop-then-create pair** rather than an in-place
  ALTER (`Diff/Index.pm`, `diff`, the same branch) — PostgreSQL has no general
  `ALTER INDEX` that can change predicate / expression / method, so recreate is
  the only correct path.
- `as_sql` for a create reuses the introspected `pg_get_indexdef` string
  verbatim when present (`Diff/Index.pm`, `as_sql`), so the emitted DDL is
  exactly what PostgreSQL itself would report.

This builds on core ADR 0007 (the introspect+diff layer and the `Diff::Compare`
contract it defines); see that ADR for the contract this one overrides. It does
not restate the test-and-compare strategy.

## Rationale

Under test-and-compare both `definition` strings come from the same
`pg_get_indexdef` on two PostgreSQL servers, so string equality is reliable, not
brittle: identical indexes serialise identically, and any real difference —
partial predicate, expression, storage param, access method — changes the string.
A field-by-field comparator would need to grow a PostgreSQL-specific field for
every one of those axes and still risk drift from what the database actually
stores; comparing the database's own rendered form sidesteps the whole problem
and is a genuine PostgreSQL strength.

karr k4 marks this as STAYS-divergent. SEAM A: "Diff/Index.pm definition-string
comparison STAYS (compares `pg_get_indexdef`, a pg strength)." SEAM B: "Index
compare stays definition-string (NOT a Compare candidate)." So while sibling
diff classes adopt core's `mk_diff_accessors` / `changed_fields`, the index
differ is explicitly exempt.

## Consequences

- Any index change is a drop+create, never an in-place alter. For large indexes
  this is more expensive than a targeted ALTER would be — but PostgreSQL offers
  no ALTER for the dimensions that actually change, so recreate is correct, and
  `CREATE INDEX CONCURRENTLY` (when used) keeps it online.
- The comparison is only as stable as `pg_get_indexdef`'s rendering. Because both
  sides come from the same PostgreSQL version under test-and-compare, formatting
  differences cannot produce false positives within a run; comparing across
  major-version servers could, and is out of scope for the in-run diff.
- `DBIO::PostgreSQL::Diff::Index` intentionally does not gain a
  `changed_index_fields` path. Future reviews proposing to "align it with the
  other diff classes" should be pointed here.

## Addendum 2026-10-20 (karr k139)

The decision stands: the definition string is what an index is compared and
created by. It has one blind spot, found by the platform: `pg_get_indexdef`
writes the same text for the index of a PRIMARY KEY or UNIQUE constraint and
for a unique index no constraint stands on. The diff created the index from
that text, so every table an upgrade made had no `pg_constraint` row of type
`p` or `u`, and the comparison could not see it.

- The comparison gains the attributes the string does not carry, beside it: the
  constraint behind the index (kind `p`, `u`, `x`, from `constraint_type`), and,
  redundant with the string but compared as the card required, the key columns
  in key order, the INCLUDE columns and the storage parameters. A difference is
  the same drop-then-create pair. `is_valid` is not compared: the index of a
  partitioned table is created from its text, `ON ONLY`, and is invalid until
  its partitions have theirs (a defect of its own, recorded on the card), so a
  comparison of validity would recreate it for ever.
- Where the target says a constraint stands behind the index, the create is
  `ALTER TABLE ... ADD CONSTRAINT name PRIMARY KEY|UNIQUE (columns)`, no
  longer the text. Where the source has the same index without the constraint,
  it is `ADD CONSTRAINT name ... USING INDEX name` -- measured on PostgreSQL
  18.6: the form without `USING INDEX` fails with `relation already exists`,
  `USING INDEX` keeps the index (same oid) and refuses a partial, expression,
  non-btree, non-unique, descending or invalid index, a partitioned table and a
  second primary key. The diff checks these in the model and refuses by
  name before any statement is written.
- EXCLUDE is still not created (the model has no elements); it is refused,
  where the diff used to create a bare index in silence.

### Second addendum 2026-10-21 (karr k139, k140)

Two cases of the first addendum, found by an independent review against a
server:

- **The index under another name.** The source has a unique index no
  constraint stands on, the target a PRIMARY KEY or UNIQUE constraint on the
  same table with the same definition but for the index's name
  (`parent_code_uidx` against `parent_code_key`). Creating the target's index
  beside it left a foreign key on the old one, and its `DROP INDEX` failed
  ("depends on index"). Decision (maintainer's hub): the index that is there is
  renamed, `ALTER INDEX ... RENAME TO <constraint>`, and the constraint put on
  it by `ADD CONSTRAINT ... USING INDEX`; no second index. An index serves one
  constraint, one the target keeps under its name is not taken, and the
  preconditions of the first addendum (unique, btree, no predicate or
  expression, valid, table not partitioned, no other primary key) hold; the
  name no longer is one. The refusal of a primary key under another name
  stays for a primary key that is a *constraint* of the source.
- **A constraint foreign keys point at.** `referenced_by` refused every drop.
  The drops of foreign keys come ahead of the drops of indexes
  (ADR 0009), so a constraint that goes (not `replaced`) is no reason for a
  refusal when the target declares foreign keys and drops or redirects the key.
  `Diff::Index->diff` takes the `foreign_keys` sections as fifth and sixth
  argument for that; a target without the section declares none, and every key
  stays a reason. A dropped-and-added constraint stands in the first half,
  ahead of any drop of a key, so a key on it is refused whatever the target
  does with the key. A key of a table the target drops, and a key the source
  model does not list (the copy at a partition), is not shown to be gone and is
  refused as before.

### Third addendum 2026-10-21 (karr k139, k140)

A second review measured three cases the rename did not reach:

- **The target's name is held by another index.** A nonunique index
  `parent_code_key` beside the unique `parent_code_uidx`: the name is taken, so
  the "changed" path dropped it and created the constraint anew, and the old
  unique index (where the key stood) was dropped at the end. Now the colliding
  index is dropped first (`replaced`, ahead of the creates) and the old one is
  renamed and taken by `USING INDEX`.
- **The constraint itself has another name** (`parent_code_uniq` against
  `parent_code_key`, a primary key `parent_id_pk` against `parent_pkey`). Add
  and drop fail when a key stands on it, so a constraint of the same kind and
  definition (but for the name) is renamed, `ALTER TABLE ... RENAME
  CONSTRAINT`, which renames its index and keeps keys, oid and data. This also
  settles the primary key under another name, which was refused; a primary key
  of another definition stays refused.
- **What still collides is refused ahead of the apply.** The server binds a
  foreign key it creates to the first (oldest) unique index over the referenced
  columns, not to the index the same run adds. A target key on the columns of
  an index the run drops, and a key of the database on an index without a
  constraint that is dropped, would fail at the end ("depends on index") and
  roll back; both are refused by name with the statement that settles it.
  Unchanged: a `replaced` drop of an index a key stands on is always refused.

Pinned live by `t/164-diff-index-collision-and-constraint-rename-live.t`.

Supersedes karr k101 (the diff creates no constraint). Pinned offline by
`t/157-diff-constraint-create.t`, live by `t/158-diff-constraint-live.t` and
`t/112-diff-index-constraint-live.t`.
