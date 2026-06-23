# ADR 0004 — Generators via GEN_ID and autoinc sequence-name discovery by trigger parsing

- Status: accepted
- Date: 2026-06-20
- Tags: storage, sequences, generators, autoinc, triggers

## Context

Firebird has no `SEQUENCE` object in the SQL-standard sense and no
`AUTO_INCREMENT`/`SERIAL` column attribute. Its equivalent is the
**generator** (newer Firebird also calls it a sequence): a named monotonic
counter advanced with `GEN_ID(name, delta)`, conventionally evaluated against
the one-row system relation `rdb$database`. Auto-incrementing columns are
implemented by convention as a generator plus a `BEFORE INSERT` trigger that
assigns `NEW.col = GEN_ID(some_generator, 1)`.

DBIO's portable surface for this is `auto_nextval` on a column and a
`sequence` source attribute. The storage layer has to (a) fetch the next value
from a named generator, and (b) for `auto_nextval` columns where the generator
name is not declared, *discover* which generator feeds a given column.

## Decision

Map DBIO's generator/auto-nextval surface onto Firebird's generator model in
`DBIO::Firebird::Storage::Common`:

- **Fetch next value** — `_sequence_fetch` (`Storage/Common.pm:30-44`) accepts
  only `nextval` (throws otherwise) and a sequence name (throws if missing),
  then runs
  `SELECT GEN_ID(<quoted seq>, 1) FROM rdb$database` and returns the value.
- **Discover the generator name** — `_dbh_get_autoinc_seq`
  (`Storage/Common.pm:46-85`) recovers the generator backing an `auto_nextval`
  column by parsing trigger source. It queries `rdb$triggers` for the table's
  user-defined (`rdb$system_flag = 0`) `BEFORE INSERT`
  (`rdb$trigger_type = 1`) triggers, then on each trigger source:
  - extracts the columns the trigger touches via `new\.("?\w+"?)`;
  - extracts the generator name via
    `(?:gen_id\s*\(\s*|next\s*value\s*for\s*)(")?(\w+)`, matching both
    `GEN_ID(gen, 1)` and the SQL-standard `NEXT VALUE FOR gen`;
  - applies Firebird's case-folding (uppercase the unquoted name/columns,
    preserve quoted ones) and returns the generator only if the trigger also
    assigns the target column.

`LongReadLen`/`LongTruncOk` are raised locally so the (BLOB) trigger source is
read whole.

## Rationale

There is no metadata column that says "column X is fed by generator Y" — the
relationship lives only in the trigger body, so trigger-source parsing is the
only way to recover an undeclared generator name, matching how the upstream
DBIx::Class Firebird driver solved it. Routing next-value fetches through
`GEN_ID(..., 1) FROM rdb$database` is the canonical Firebird idiom and the only
portable spelling that works across the supported versions. Putting both on
`Storage::Common` means the Firebird and InterBase backends (ADR 0001) share
one implementation.

The case-folding and quote-awareness are load-bearing, not incidental: Firebird
upper-cases unquoted identifiers, so the discovered generator/column names must
be normalised the same way the server stored them, and a quoted identifier must
be preserved verbatim — otherwise the column-match guard would miss and the
wrong generator (or none) would be returned.

## Consequences

- `auto_nextval` works even when the generator name is not declared, at the
  cost of depending on a recognisable trigger shape: a `BEFORE INSERT` trigger
  using `GEN_ID(...)` or `NEXT VALUE FOR ...` against `NEW.col`. Triggers that
  obscure the generator (computed name, indirection) will not be discovered.
- `last_insert_id` reliably works only on Firebird 2+, while `auto_nextval`
  works on earlier versions too — recorded in the CAVEATS POD of
  `Storage::Common`.
- The two regexes encode Firebird trigger DDL conventions; they must track any
  future generator-call spelling the driver wants to support.
