# ADR 0004 — SQLMaker select.where paren-restore + expand_op

- Status: accepted
- Date: 2026-06-19
- Tags: sqlmaker, sql-abstract, expand-op, backfill

## Context

`SQL::Abstract` carries a special case for DBIx::Class: it only wires up its
DBIx::Class-flavoured `select.where` rendering and its operator handling for
classes that `->isa('DBIx::Class::SQLMaker')`. DBIO's clean rename (ADR 0001)
means no DBIO SQLMaker satisfies that `isa` gate. With the gate un-tripped and
DBIO now on canonical `SQL::Abstract` (ADR 0002), two upstream behaviours
silently dropped:

1. `select()` emitted a bare `WHERE cond` instead of the canonical
   `WHERE ( cond )` that DBIx::Class produced and that downstream code and
   tests expect.
2. The old special-op system stayed active, instead of every driver expressing
   its operators through `SQL::Abstract`'s newer `expand_op` mechanism.

## Decision

In `DBIO::SQLMaker::new` (`lib/DBIO/SQLMaker.pm:20-34`), restore both
behaviours, deliberately and together:

- Install a `render_clause{'select.where'}` override that routes the SELECT's
  WHERE through `SQL::Abstract`'s `where()` and trims surrounding whitespace —
  reproducing the canonical `WHERE ( cond )` parenthesisation that the `isa`
  gate would have provided.
- Set `disable_old_special_ops => 1`, so every DBIO driver expresses its
  operators through the new `expand_op` mechanism (see the PostgreSQL and
  Oracle SQLMakers) rather than the legacy special-op path.

These two are one decision: the in-code comment states "the two go together."
Routing WHERE through `where()` and switching operators to `expand_op` are the
matched pair that re-establishes DBIx::Class-equivalent rendering on a
SQLMaker hierarchy `SQL::Abstract` no longer recognises by `isa`.

## Rationale

The fork's rename (ADR 0001) is what removed the upstream special-casing — that
is the direct, evidence-backed cause, recorded in the code comment at
`SQLMaker.pm:20-27`. Rather than re-introduce an `isa('DBIx::Class::SQLMaker')`
ancestry purely to satisfy `SQL::Abstract` (which would reintroduce exactly the
compatibility coupling ADR 0001 rejected), DBIO re-implements the two
behaviours it actually wants. Pairing the paren-restore with
`disable_old_special_ops` is deliberate because the `where()` route and the
`expand_op` operator path are the consistent modern combination; mixing the
restored WHERE rendering with the *old* special-op system would be
self-inconsistent. Drivers therefore get a single, predictable operator model
(`expand_op`) and canonical WHERE output without depending on the upstream
`isa` gate.

## Consequences

- Every DBIO driver renders operators via `expand_op` and produces canonical
  `WHERE ( cond )`. New driver SQLMakers express operators through `expand_op`,
  not the legacy special-op API.
- This re-implementation is the seam where a separate defect lives. **karr #26**
  — top-level WHERE double-wrapped as `WHERE ( ( ... ) )` — is a *bug* in this
  `select.where` override: installed `SQL::Abstract 2.000001`'s `where()` adds
  one paren layer while the already-expanded top-level `-and` node was already
  wrapped, yielding two. That defect is **distinct from this ADR**: ADR 0004 is
  the deliberate decision to restore parens + switch to `expand_op`; karr #26
  is the over-wrapping bug in how the restore is currently implemented. Do not
  conflate them — fixing #26 must preserve this decision (single canonical
  parens, `expand_op` operators), not revert it.
- The override is coupled to `SQL::Abstract`'s internal `where()` /
  `render_clause` behaviour (ADR 0002); engine-internal changes upstream can
  shift the paren layering and must be regression-tested here.
