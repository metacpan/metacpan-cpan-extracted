# ADR 0004 — Auto-increment via BEFORE INSERT trigger-body parsing of ALL_TRIGGERS

- Status: accepted
- Date: 2026-06-22
- Tags: storage, sequences, autoinc, triggers, oracle

## Context

DBIO's portable auto-increment surface is `auto_nextval` on a column plus a
`sequence` source attribute. Pre-12c Oracle has no `IDENTITY` column and no
`SERIAL`; the conventional implementation is a `SEQUENCE` object plus a
`BEFORE INSERT` trigger that assigns `:new.col := seq.nextval`. There is **no
metadata column anywhere in the data dictionary** that records "column X is fed
by sequence Y" — the relationship lives only inside the trigger body. So for an
`auto_nextval` column whose `sequence` is not declared in `column_info`, the
storage layer must *discover* which sequence backs the column, and it can only do
that by reading and parsing trigger source.

## Decision

`DBIO::Oracle::Storage::AutoIncrement` recovers the sequence by querying
`ALL_TRIGGERS` and parsing trigger bodies (`Storage/AutoIncrement.pm:17-103`):

- **Query** `ALL_TRIGGERS` for the table's `ENABLED`, `%BEFORE%`, `%INSERT%`
  triggers, scoped to the column's schema (defaulting to the current user via
  `= USER` when the source name carries no schema, `AutoIncrement.pm:36-49`).
  `LongReadLen` is raised locally to 64 KiB so the full trigger body is read
  (`AutoIncrement.pm:33`).
- **Filter** to triggers whose body references `:new.<col>`
  (`AutoIncrement.pm:51-56`), then extract every `<name>.nextval` occurrence from
  each body via regex (`AutoIncrement.pm:58-61`).
- **Disambiguate** deliberately and refuse to guess:
  - one matching trigger referencing exactly one sequence → use it;
  - one matching trigger referencing *multiple* sequences →
    **`throw_exception`** telling the user to set `sequence` explicitly;
  - multiple matching triggers → narrow to those that assign `into :new.<col>`;
    use it only if that leaves exactly one trigger with exactly one sequence,
    else **`throw_exception`** listing the candidates;
  - no matching trigger → **`throw_exception`**.
- `_dbh_last_insert_id` then fetches `CURRVAL` of the resolved sequence via
  `_sequence_fetch` against `DUAL` (`AutoIncrement.pm:105-124`); the resolved
  name is memoised into `column_info->{sequence}`.

Quoted/qualified names are preserved: a sequence name containing `"` is returned
as a SCALAR ref so downstream code treats it as already-quoted
(`AutoIncrement.pm:91-96`).

## Rationale

Trigger-body parsing is not a hack of last resort — it is the *only* way to
recover an undeclared sequence name on pre-IDENTITY Oracle, because the binding
exists nowhere else, and it matches how the upstream DBIx::Class Oracle driver
solved it. Firebird faces the identical "no column→generator metadata" problem
and solves it the same way (firebird ADR 0004), which is reassurance that the
approach is the family norm for this class of engine, not an Oracle one-off.

The throw-rather-than-guess policy is the load-bearing design choice. An
auto-increment column silently bound to the wrong sequence corrupts primary
keys, so every ambiguous case (multiple sequences, multiple triggers, no clear
`:new.col` assignment) fails loud with an actionable message ("specify the
correct `sequence` explicitly in column_info") rather than picking one. The
explicit `sequence` attribute is always the escape hatch, and discovery is only
attempted when it is absent.

## Consequences

- `auto_nextval` works without declaring `sequence`, at the cost of depending on
  a recognisable trigger shape: an `ENABLED BEFORE INSERT` trigger that
  references `:new.<col>` and a single `<seq>.nextval`. Triggers that obscure the
  sequence (computed name, multiple sequences, indirection) are intentionally
  *not* guessed — they raise, and the user declares `sequence` instead.
- The regexes encode Oracle trigger/PL-SQL conventions (`:new.col`,
  `<name>.nextval`); they must track any future spelling the driver wants to
  support, and quote-awareness must be preserved so quoted names match what the
  dictionary stored.
- This is read-only introspection of `ALL_TRIGGERS`; the same trigger-parsing
  approach feeds `DBIO::Oracle::Introspect` sequence detection, keeping live
  auto-increment and introspection consistent.

## Related

- firebird ADR 0004 (generator/autoinc discovery by trigger parsing — the
  directly parallel decision in the other no-IDENTITY engine)
- ADR 0001 (storage mixin composition — `AutoIncrement` is one of the composed
  `Storage::*` concerns)
