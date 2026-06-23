# 5. PRAGMA table_info is the authority for column nullability

Date: 2026-06-20

## Status

Accepted

## Context

DBD::SQLite's `column_info` (and its prepared-statement `NULLABLE` fallback)
does not report `is_nullable` reliably. PRIMARY KEY columns come back as
nullable, and columns constrained by `UNIQUE ... NOT NULL` can also be wrong.
Downstream DBIO consumers (`DBIO::Result/columns_info_for`, schema diffs,
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

## Related

- ADR 0001 (native introspection this feeds)
- ADR 0002/0003 (diff and rebuild depend on a faithful introspected model)
