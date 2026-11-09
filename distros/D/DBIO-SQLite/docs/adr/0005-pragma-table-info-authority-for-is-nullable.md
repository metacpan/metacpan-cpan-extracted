# 5. PRAGMA table_info is the authority for column nullability

Date: 2026-06-20

## Status

Accepted, amended 2026-08-05 (karr k29, karr k32) -- see "Amendment" below.
The rule below that "a key column is not nullable" and the mirroring of it in
`target_from_compiled` are both retracted there; everything else stands.

## Context

DBD::SQLite's `column_info` (and its prepared-statement `NULLABLE` fallback)
does not report `is_nullable` reliably. PRIMARY KEY columns come back as
nullable, and columns constrained by `UNIQUE ... NOT NULL` can also be wrong.
Downstream DBIO consumers (`DBIO::Storage::DBI::columns_info_for`, schema diffs,
`DBIO::Generate`) need correct nullability, so trusting DBD::SQLite's value
directly produces wrong DDL and wrong diffs.

There is a second, SQLite-specific subtlety: `PRAGMA table_info` reports
`notnull=0` for PRIMARY KEY columns even though a PK column is logically
non-nullable -- the PK constraint is tracked separately from the NOT NULL
attribute. So neither DBD::SQLite nor a naive reading of `table_info` alone is
correct; the rule is "NOT NULL if declared NOT NULL *or* part of the primary
key".

This rule is needed in more than one place -- the live-storage column lookup
(`DBIO::SQLite::Storage::_dbh_columns_info_for`) and the introspection model
(`DBIO::SQLite::Introspect`) -- so it must not be re-encoded inconsistently.

## Decision

`PRAGMA table_info` is the authoritative source for SQLite column nullability,
layered over DBD::SQLite's `column_info` result.

The combining rule lives in one place,
`DBIO::SQLite::Util::column_is_nullable($not_null, $is_pk)`, which returns
"not nullable" when the column is either declared `NOT NULL` or part of the
primary key. Both `DBIO::SQLite::Storage::_dbh_columns_info_for` and
`DBIO::SQLite::Introspect` use this single helper.

Relatedly, `DBIO::SQLite::Diff::target_from_compiled` deliberately reports PK
columns as `not_null = 0` in the *target* model, to match how `PRAGMA
table_info` describes the *source* model -- so the two sides of a diff agree
and a PK does not show up as a spurious nullability change.

## Consequences

- Nullability reported to DBIO is correct for PK and unique-NOT-NULL columns,
  despite DBD::SQLite's unreliable `NULLABLE`.
- The PK-implies-NOT-NULL rule has exactly one definition, shared by the live
  storage path and the introspection path, so they cannot disagree.
- An extra `PRAGMA table_info` query runs per table during column-info lookup;
  acceptable for the schema-management paths where this matters.
- The diff's compiled-target normalisation must keep mirroring the
  `table_info` PK-nullability convention, or PK columns would diff as changed.

## Amendment (2026-08-05)

Two of the statements above are wrong about SQLite and have been replaced. The
single-helper principle is not affected -- it is what made the correction one
edit rather than four.

**"NOT NULL if declared NOT NULL *or* part of the primary key" is retracted**
(karr k29, core k129 / ADR 0038). A `PRIMARY KEY` on a rowid table really
does store NULL, repeatedly, and the NULLs do not even collide with one
another; SQLite documents it as a bug kept on purpose. Since `is_nullable` is
what `DBIO::Generate` writes into a regenerated result class and what
`DBIO::SQLite::DDL` turns into `NOT NULL`, the old rule made
introspect → generate → deploy emit a table that refused the rows it was
generated from. `column_is_nullable` therefore takes a third argument, "is this
key the rowid alias", and only the alias is reported non-nullable on the
strength of being a key.

**The one shape the declaration cannot describe is the rowid alias.** `INTEGER
PRIMARY KEY` on a rowid table cannot hold NULL whatever it was declared as --
there `NULL` is the "assign a rowid" input token, and an INSERT of NULL is
accepted and assigns a rowid even when the column says `NOT NULL` (measured
against libsqlite 3.51.1). `PRAGMA table_info` reports the declaration, so the
same alias reads `notnull = 0` written one way and `notnull = 1` written the
other. It is identified with `DBIO::SQLite::Util::pk_is_rowid_alias`, which
asks `PRAGMA index_list`: every primary key materialises an `origin = 'pk'`
automatic index except the alias. Nothing cheaper is correct -- `table_info`
reports `type=INTEGER notnull=0 pk=1` for both `id INTEGER PRIMARY KEY` and
`id INTEGER PRIMARY KEY DESC`, and affinity does not separate them either.

**`table_info` remains the authority, but for the alias the model reports the
truth rather than the declaration** (karr k32). `DBIO::SQLite::Introspect::Columns`
stores `not_null` as the negation of `column_is_nullable`, so the raw model key
and what `table_columns_info` reports cannot disagree, and the two spellings of
one alias produce one model.

**The compiled target no longer mirrors anything** (karr k32). Zeroing
`not_null` on every primary-key column in `target_from_compiled` was correct for
the alias and for a key nobody declared `NOT NULL`, and wrong for a key declared
`NOT NULL` and for a `WITHOUT ROWID` key -- `table_info` reports `notnull = 1`
for both of those, so a table diffed against the schema it had just been
deployed from, and on the upgrade path that alter escalated to a full
`DBIO::SQLite::Diff::Rebuild` (ADR 0003). The target now carries `not_null`
exactly as the compiled model states it, like every other driver's
`target_from_compiled`; the alias is reconciled on the introspect side, which is
the only side with a database to ask.

Not fixed by any of this, and not SQLite's to fix: a column whose result class
omits `is_nullable` altogether compiles to `not_null = 1`
(`DBIO::Schema::Type::canonical_column`) while no driver's DDL emits `NOT NULL`
for it, so such a column diffs against its own deployed table whether it is a
key or not. Filed as core k147.

## Related

- ADR 0001 (native introspection this feeds)
- ADR 0002/0003 (diff and rebuild depend on a faithful introspected model)
- core ADR 0038 (the `is_pk` fold this driver overrides, and its escape hatch)
