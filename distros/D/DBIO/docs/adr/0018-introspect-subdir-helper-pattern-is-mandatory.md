# ADR 0018 — Introspect subdir-helper pattern is mandatory for every driver

- Status: accepted
- Date: 2026-06-20
- Tags: introspect, architecture, drivers, family-policy, cross-driver, backfill

## Context

Every DBIO database driver introspects a live schema into the canonical model
that `DBIO::Introspect::Base` (`lib/DBIO/Introspect/Base.pm`) reads. The
established family layout decomposes that work into per-artifact fetch helpers
under an `Introspect/` subdirectory — `Introspect::{Tables,Columns,Indexes,ForeignKeys}`
— each a thin module whose interface is `fetch($dbh, $schema, $tables)` →
hashref for one section of the model. PostgreSQL, SQLite, Oracle and Sybase all
carry this layout.

The rule that this pattern is the family standard was first written down in the
**dbio-sybase** local ADR 0001 (`docs/adr/0001-*` in that repo), which framed it
as a family-wide decision: "The pattern is identical across every DBIO driver …
core base classes (`DBIO::Introspect::Base`, `DBIO::Diff::Base`) assume this
decomposition." But a family-wide rule recorded in one driver's repo gives that
driver no authority over the others, and the rule has already been tested:
**dbio-mysql** (karr mysql#6) collapsed its `Introspect/` into a single
`Introspect.pm`, with the four readers reduced to private `_build_*` methods, and
recorded that collapse as a conscious local deviation in its own ADR 0006. That
left MySQL as the lone diverging driver and raised a question that no single
driver repo can answer: may a driver opt out of the subdir pattern when its
readers are tightly coupled and there is no sister-engine variant to justify the
fan-out? (karr core#45.)

By the ownership rule (family-wide → core), the decision and its authority belong
here, in core — not in the Sybase repo and not negotiable per driver.

## Decision

The `Introspect/{Tables,Columns,Indexes,ForeignKeys}` subdir-helper pattern is
**mandatory for every DBIO driver**. Each driver's introspector decomposes into
one fetch helper per model section under an `Introspect/` subdirectory. There are
**no collapse exceptions** — a driver may not fold its readers into a single
`Introspect.pm`, regardless of how tightly coupled the readers are or whether a
variant-override sister engine exists.

This core ADR is the single source of the family rule. The Sybase ADR 0001 is
no longer the authority for it.

## Rationale

The leverage of the pattern is not local depth — viewed in isolation each helper
is shallow, one SQL query against the catalog. The leverage is **cross-driver
navigability**: a maintainer who learns the `Introspect/Columns.pm` seam in one
driver finds the matching seam in every other, and a behaviour-relevant change to
how one artifact is fetched lands in the same file in each engine. A single
driver collapsing its helpers breaks that family symmetry for a marginal local
tidiness win — a bad trade across a family of drivers.

The pattern is also the shape the **core base class assumes**. `DBIO::Introspect::Base`
defines the canonical model as up to five independent per-table sections —
`tables`, `columns`, `indexes`, `unique_constraints`, `foreign_keys`
(`lib/DBIO/Introspect/Base.pm`, "CANONICAL MODEL") — and ships one default contract
method per section (`table_keys`, `table_columns`, `table_columns_info`,
`table_pk_info`, `table_uniq_info`, `table_fk_info`). The subdir helpers are the
per-driver fetch side of exactly that decomposition: one helper produces each
section the base class then reads. The base class's structure is the standing
argument for the file layout that feeds it.

Tight coupling between a driver's readers (shared `$tables` filter, shared
size-parsing, shared `_aggregate_by_ordered` grouping) is not a licence to
collapse. Genuinely shared logic is deduplicated by **extracting an exported
helper** the subdir modules call, which preserves the per-artifact layout while
removing the real copy — not by merging the modules.

## Consequences

- Future architecture reviews must not re-propose flattening these submodules in
  any driver; point them here. This supersedes the family-policy question raised
  in karr core#45, which is resolved in the strict direction (no per-driver
  exception).
- **dbio-mysql is non-compliant.** Its `Introspect/` is collapsed into a single
  `Introspect.pm` (four readers as private `_build_*`; karr mysql#6; recorded in
  dbio-mysql ADR 0006). Under this decision MySQL must be **re-split** back into
  `Introspect::{Tables,Columns,Indexes,ForeignKeys}` to match the family, and its
  ADR 0006 is then **superseded**. (Only Introspect is affected — dbio-mysql's
  `Diff/{Table,Column,Index,ForeignKey}.pm` is already split and stays as is.)
- **dbio-sybase ADR 0001 is reduced.** It stops claiming family-wide authority and
  instead references this core ADR as the source of the rule; its local content
  shrinks to the Sybase-specific application of it (and the separate Sybase
  `Diff/` shared-helper note).
- New driver-shaped fetch behaviour goes in the matching `Introspect/` submodule,
  keeping the per-engine layout consistent across the family.
- Shared rendering/normalisation logic is deduplicated via exported helper
  functions, preserving the subdir layout while removing real copies.
