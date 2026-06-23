# ADR 0009 — Diff fidelity: SCALAR-ref expression defaults and is_deferrable round-trip

- Status: accepted
- Date: 2026-06-22
- Tags: diff, introspect, defaults, foreign-keys, deferrable, oracle

## Context

Oracle's native introspect/diff layer (built on core ADR 0007's test-and-compare
migration and core ADR 0019's desired-state semantics) adopts the core
`DBIO::Diff::Op` / `DBIO::Diff::Compare` / `DBIO::Introspect::Base` building
blocks. But two pieces of Oracle metadata do not survive the generic core path
unchanged, and getting them wrong produces *phantom diffs* — a migration that
keeps reporting a change that does not exist — or *lost information* — a
constraint attribute that silently disappears across a round-trip.

1. **Expression column defaults.** Oracle stores an expression default (e.g.
   `SYSDATE`, `current_timestamp`) and introspection represents it as a Perl
   SCALAR ref (`\'current_timestamp'`), while a literal default is a plain
   string. Core's generic field comparison would stringify the ref to
   `SCALAR(0x...)` and report a difference on *every* expression default, every
   diff run.

2. **FK deferrability.** Oracle `DEFERRABLE` foreign keys are first-class — the
   driver's `with_deferred_fk_checks` depends on the constraint actually being
   declared deferrable. Core's default FK introspection contract drops the
   `is_deferrable` attribute, so a round-trip (introspect → diff → emit) would
   lose it.

## Decision

Override exactly the two seams that lose fidelity, and adopt core everywhere
else:

- **SCALAR-ref default normalization** — `DBIO::Oracle::Diff::Column::_default_key`
  (`Diff/Column.pm:43-55`) produces a canonical comparison key: a SCALAR ref is
  unwrapped, lowercased and trimmed to its expression text; a plain string is
  quoted; the "no default" cases (undef, literal `null`, the `\'null'` expression
  ref) all collapse to `undef` so core's desired-state rule (core ADR 0019)
  treats a target-undef as "don't care" and skips the field. The key mirrors the
  rendering in `as_sql`, so comparison and emission cannot diverge. Everything
  else in the column diff uses core's `changed_fields`
  (`Diff/Column.pm:10`, adopting `DBIO::Diff::Compare`).
- **is_deferrable round-trip** — `DBIO::Oracle::Introspect::ForeignKeys`
  introspects deferrability directly from `ALL_CONSTRAINTS`
  (`CASE WHEN cc.deferrable = 'DEFERRABLE' THEN 1 ELSE 0 END`,
  `Introspect/ForeignKeys.pm:40`) and carries `is_deferrable` through to the
  model (`ForeignKeys.pm:80-89`). The FK grouping itself uses core's
  `_aggregate_by_ordered` (two-level: by `from_table`, then by `fk_name`, because
  two FKs in different tables can share a name, `ForeignKeys.pm:69-91`) — only the
  `is_deferrable` attribute is the Oracle-specific addition core's default drops.

## Rationale

Both overrides exist to keep the diff *honest*. The default-key normalization is
the difference between a stable migration and one that proposes a no-op
`MODIFY ... DEFAULT current_timestamp` on every run; the comment at
`Diff/Column.pm:34-42` records the exact failure ("a naive string compare
stringifies the ref to SCALAR(0x...) and reports a phantom diff on every
expression default"). Mirroring `as_sql`'s rendering in the comparison key is
what guarantees "what we compare equal, we emit equal" — the property a diff must
have to be idempotent.

`is_deferrable` is kept local rather than pushed into core because it is the one
FK attribute Oracle's deploy/runtime behaviour (`with_deferred_fk_checks`,
`DEFERRABLE` DDL) actually depends on, and core's default contract drops it;
overriding the introspect carries it through without forcing a core change. This
is a deliberate, scoped divergence from the generic introspect defaults (the
pre-squash audit, karr #8 Seams B/C/E, explicitly chose "adopt core, keep these
two").

## Consequences

- Oracle diffs are idempotent across expression defaults: re-running diff on an
  unchanged schema with `SYSDATE`/`current_timestamp` defaults reports no
  change.
- `is_deferrable` survives introspect → diff → emit, so deferrable FKs are not
  silently downgraded and `with_deferred_fk_checks` keeps working after a
  round-trip.
- `_default_key` is coupled to `as_sql`'s default rendering — **the two must
  change together.** If `as_sql` changes how it spells a default, the comparison
  key must change in lock-step or phantom diffs return.
- These are the only two intentional deviations from the generic core
  introspect/diff contract in this driver; the rest (`Diff::Op` accessors,
  `changed_fields`, `_aggregate_by_ordered`, the contract methods) is adopted
  from core. New comparison logic should prefer the core helpers and only deviate
  with a recorded reason like these two.

## Related

- core ADR 0007 (native introspect + diff test-and-compare — the layer this
  refines)
- core ADR 0019 (desired-state diff ignores target-undef fields — the rule
  `_default_key`'s undef returns are written to cooperate with)
- core ADR 0021 (`constraint_name` optional canonical FK key — the FK-key
  contract this introspect feeds, while adding the `is_deferrable` attribute core
  drops)
- ADR 0002 (SAVEPOINT deploy — the migration that consumes these diffs)
- ADR 0008 (pure `DBIO::Oracle::Type` functions — used by the offline column diff
  path)
