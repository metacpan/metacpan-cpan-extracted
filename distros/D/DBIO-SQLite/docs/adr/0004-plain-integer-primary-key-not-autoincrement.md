# 4. Plain INTEGER PRIMARY KEY, not AUTOINCREMENT

Date: 2026-06-20

## Status

Accepted (supersedes the original AUTOINCREMENT choice from commit `add9e7a`)

## Context

For a single-column integer auto-increment primary key, the initial driver
emitted `INTEGER PRIMARY KEY AUTOINCREMENT` (initial commit `add9e7a`,
`Changes`), with a code comment claiming AUTOINCREMENT was the only way to opt
into SQLite's rowid alias.

That claim is wrong. In SQLite a plain `INTEGER PRIMARY KEY` column is
*already* a rowid alias. The `AUTOINCREMENT` keyword adds only one extra
guarantee: rowids are never reused after `DELETE` (SQLite tracks the high-water
mark in `sqlite_sequence`).

That extra guarantee is a behavioural change, not a no-op. Tests that delete
rows and then re-insert expect the rowid to start back at the low end;
AUTOINCREMENT makes ids keep climbing instead. This broke
`t/multi_create/in_memory.t`, `t/relationship/custom.t` and
`t/resultset/update_delete.t` (karr #10, commit `f793d21`). DBIx::Class and
SQL::Translator's SQLite producer also emit plain `INTEGER PRIMARY KEY`, so
AUTOINCREMENT was both incorrect for our semantics and a divergence from the
baseline.

## Decision

`DBIO::SQLite::DDL` emits a plain `INTEGER PRIMARY KEY` (no `AUTOINCREMENT`)
for single-column integer auto-increment PKs. The column is still a rowid
alias and still issues auto-incrementing ids; only the never-reuse guarantee
is dropped.

The whole-table rebuild path (ADR 0003) does not re-derive this -- it reuses
the captured `CREATE TABLE` text verbatim, so whatever a table was originally
deployed with (including AUTOINCREMENT, for tables deployed before this
decision or by external tooling) is preserved faithfully across a rebuild.

## Consequences

- Delete-then-reinsert restarts rowids at the low end, matching DBIx::Class
  behaviour and the integration suite's expectations.
- Auto-increment id issuance is unaffected for normal inserts.
- DDL output matches the DBIx::Class / SQLT SQLite producer, easing
  round-trip and comparison.
- The two tests that hard-coded the old AUTOINCREMENT output were updated
  intent-preservingly; the "auto-increment still issues ids" assertions were
  kept. `t/37-rebuild.t` still exercises AUTOINCREMENT input strings on purpose,
  to prove the rebuild preserves captured DDL verbatim (ADR 0003).

## Related

- ADR 0001 (native schema management -- the DDL generator)
- ADR 0003 (rebuild reuses captured DDL, so pre-existing AUTOINCREMENT survives)
- karr #10 (root-cause diagnosis and fix)
