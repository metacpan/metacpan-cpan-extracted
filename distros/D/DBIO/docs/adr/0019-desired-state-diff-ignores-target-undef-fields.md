# ADR 0019 — Desired-state diff ignores target-undef fields (always-on)

- Status: accepted
- Date: 2026-06-20
- Tags: diff, migration, deploy, drivers, cross-driver, family-policy

## Context

The native diff layer (ADR 0007) compares a *live introspect* model against a
*desired* model and emits ALTER operations for what differs. The comparison
kernel is `DBIO::Diff::Compare` (`lib/DBIO/Diff/Compare.pm`), whose generic
field-walk `changed_fields($old, $new, %spec)` takes the live/introspected side
as `$old` and the target/desired side as `$new`.

A portable DBIO schema does not prescribe server-assigned column attributes —
charset, collation, server-default expressions, server-normalised sizes. The
driver leaves those fields `undef` on the target side because the schema simply
did not say what they should be. The live database, however, always reports a
concrete value for them (e.g. `utf8mb4` on MariaDB, a normalised `size`,
`NO ACTION` as a foreign-key referential default). Comparing an `undef` target
against a real live value as if `undef` meant "set this to NULL/empty" makes the
diff emit a **phantom ALTER on every upgrade** — engine-agnostic, it bites any
driver whose live introspect is richer than the portable schema.

A skip rule existed but was **opt-in**: callers had to pass `desired_state => 1`
into `changed_fields` for it to fire. `changed_column_fields` set it, but drivers
that passed their own field spec to `changed_fields` directly (e.g. PostgreSQL)
and the sibling comparators `changed_index_fields` / `changed_fk_fields` did not
— so phantom ALTERs still escaped through the comparators that forgot the flag,
despite the mechanism being present. (karr core#44.)

## Decision

The desired-state contract is **always on** in core. Any non-`bool`
`scalar`/`type`/`dim`/`array` field whose value on the target side (`$new`) is
`undef` is treated as "don't care" and skipped from the comparison entirely —
`undef` on the target is never interpreted as "set to NULL/empty".

The rule fires **only when the target side is `undef`**:

- target `undef`, live set → **not** a change (don't care, leave the live value)
- both sides set and different → **still** a real change
- target set, live `undef` → **still** a real change (the schema prescribes a
  value the live DB lacks)

`bool` fields are exempt: `undef` there is a real value (`0`), so an absent flag
and an explicit `0` already compare equal and must not be skipped.

The `desired_state => 1` key remains accepted for back-compat but is **vestigial**
— `changed_fields` deletes it on entry and the contract applies regardless.

## Rationale

The phantom-ALTER bug was not that the skip rule was wrong, but that it was
*per-caller* — solved once for column comparison and then silently re-broken by
every comparator and driver that drove the diff walk without re-asserting the
flag. Making the contract a property of the kernel (`changed_fields`) instead of
a property of each call site solves it **once** and reaches all three canonical
comparators — column, index, foreign key — automatically, including drivers that
pass a bespoke field spec straight to `changed_fields`. A correctness invariant
this load-bearing belongs in core, not in a flag each driver must remember.

Skipping only on the **target** side is what keeps the rule honest: it encodes
"the desired schema didn't say" (a real don't-care) without swallowing the two
genuine changes — both-set-and-different, and target-prescribes-but-live-lacks.
A symmetric either-side-undef skip would hide the latter and is explicitly wrong;
the regression test (`t/diff-desired-state-undef.t`, cases (b)/(c)) pins this
both at the raw `changed_fields` level and through the real `diff_nested` walk,
and exercises the foreign-key comparator to prove the contract reaches beyond
columns.

## Consequences

- Every canonical comparator in `DBIO::Diff::Compare`
  (`changed_column_fields`, `changed_index_fields`, `changed_fk_fields`) and any
  driver calling `changed_fields` with its own spec inherits the desired-state
  skip with no opt-in. Drivers no longer need to pass — or remember — a flag.
- The `desired_state => 1` argument is dead weight: still tolerated, still set by
  `changed_column_fields` and friends, but with no effect. New code should not
  pass it; existing passers need no change.
- A portable schema that intentionally leaves a server-assigned attribute `undef`
  will never be "corrected" toward NULL by a migration. Conversely, to *clear* a
  server attribute a schema must express that as a real value the driver maps,
  not by leaving the field `undef`.
- `bool` remains the one exempt group; any future field whose `undef` is a
  meaningful value (rather than "unspecified") must be declared `bool` (or a new
  group with matching semantics), not `scalar`, or the skip will wrongly hide it.
- Pins the desired-state half of the diff layer introduced in ADR 0007. Relates
  to the `changed_*_fields` comparator naming settled in karr #21/#22.
