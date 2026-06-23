# ADR 0001 — Keep the per-engine subdir-helper pattern in Introspect/ and Diff/

- Status: accepted
- Date: 2026-06-09
- Tags: introspect, diff, architecture, family-policy

## Context

`DBIO::Sybase::Introspect` is composed of thin fetch helpers
(`Introspect::{Tables,Columns,Indexes,ForeignKeys}`), and `DBIO::Sybase::Diff`
of per-artifact helpers (`Diff::{Table,Column,Index}`). Viewed in isolation
several of these modules are **shallow**: their interface
(`fetch($dbh, $schema, $tables)` → hashref, or `diff($source, $target)` → ops)
is nearly as simple as their implementation, which is mostly one SQL query or
one comparison loop. An architecture review (2026-06-09) flagged them as
candidates for flattening into their parent module.

When this ADR was first written it also asserted the *family-wide* authority for
the Introspect subdir pattern. That authority has since moved to core — a
family-wide rule recorded in one driver's repo gives that driver no standing
over the others. This ADR is reduced accordingly: it records only the
Sybase-specific application of the pattern and the separate Sybase `Diff/`
shared-helper note.

## Decision

Keep the subdir-helper pattern in this driver. Do **not** collapse the
`Introspect/*` or `Diff/*` submodules into their parents.

The rule that the `Introspect/{Tables,Columns,Indexes,ForeignKeys}` layout is
mandatory for *every* DBIO driver is owned by **core ADR 0018**
(`dbio`, `docs/adr/0018-introspect-subdir-helper-pattern-is-mandatory.md`),
which is the single source of that rule. This ADR no longer asserts cross-driver
authority; Sybase follows core ADR 0018 for Introspect and applies the same
shape locally to `Diff/`.

## Rationale

The cross-driver rationale for the Introspect pattern — navigability across the
family, and the decomposition the core base classes assume — belongs to core
ADR 0018; see there.

What remains Sybase-local is duplication *between* `Diff/` helpers: a Sybase type
map or DEFAULT formatter copied between `DDL` and `Diff/Table` is a real copy,
and it is removed by extracting shared helpers — `DBIO::Sybase::DDL`'s exported
`sybase_column_type` / `sybase_default_clause` — that the submodules call, not by
merging the modules. This keeps the per-artifact `Diff/` layout while removing
the real copies.

## Consequences

- Future architecture reviews should not re-propose flattening these
  submodules; point them at core ADR 0018 (Introspect) and this note (Diff).
- New driver-shaped behaviour goes in the matching submodule, keeping the
  per-engine layout consistent with the other DBIO drivers.
- Shared rendering/normalisation logic is deduplicated via exported helper
  functions, preserving the subdir layout while removing real copies.
