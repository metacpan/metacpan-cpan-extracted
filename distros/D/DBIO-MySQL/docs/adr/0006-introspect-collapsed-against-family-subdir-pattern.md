# ADR 0006 — Introspect is one module here, deviating from the family subdir pattern

- Status: superseded by core ADR 0018 (2026-06-21)
- Date: 2026-06-20
- Tags: introspect, architecture, deviation, family-divergence, backfill, superseded

## Superseded (2026-06-21)

The family-level question this ADR deferred (core karr #45 — "may a driver
deviate from the Introspect subdir-helper pattern?") has been resolved
**strict**: core ADR 0018 ("Introspect subdir-helper pattern is mandatory")
makes the `Introspect/{Tables,Columns,Indexes,ForeignKeys}` layout binding
family-wide with **no collapse exceptions**, explicitly stating that tight
coupling is not a licence to merge.

`DBIO::MySQL::Introspect` has therefore been re-split back into the subdir
form (karr dbio-mysql #13): four thin per-section readers plus a
`DBIO::MySQL::Introspect::Util` leaf holding the genuinely shared `$tables`
filter and `column_type` size parser (the coupling is deduplicated by an
extracted helper, not by collapse). The deviation recorded below no longer
exists in the code; this ADR is retained only as the historical record of the
exception and its resolution.

The original (now-obsolete) decision follows unchanged.

## Context

Every other DBIO driver decomposes introspection into a per-artifact subdir of
thin fetch helpers: `Introspect/{Tables,Columns,Indexes,ForeignKeys}.pm`
(PostgreSQL carries even more — Sequences, Types, Triggers, …; SQLite, Sybase
and Oracle all carry the four-helper form). That family-wide pattern is an
*explicitly recorded decision*: `dbio-sybase` ADR 0001 ("Keep the per-engine
subdir-helper pattern") says do **not** collapse these submodules, on the
grounds that the leverage is cross-driver navigability — "a maintainer who
learns the layout in one driver can find the matching seam in any other" — and
that the core base classes assume the decomposition.

`DBIO::MySQL::Introspect` does **not** follow this. A local refactor (karr #6)
collapsed `Introspect/{Tables,Columns,Indexes,ForeignKeys}.pm` into a single
`Introspect.pm`, with the four readers as private methods
(`_build_tables` / `_build_columns` / `_build_indexes` / `_build_foreign_keys`)
and the directory removed. This makes MySQL the lone driver whose Introspect
diverges from the family layout. (Note: the **Diff** side here is *not*
collapsed — `Diff/{Table,Column,Index,ForeignKey}.pm` still exist, matching the
family. The deviation is Introspect-only.)

## Decision

Keep `DBIO::MySQL::Introspect` as a single module. Record this as a conscious,
local deviation from the family subdir pattern — not an oversight to be
"corrected" back into a subdir on the next architecture pass.

The contract is unchanged: this class still subclasses core
`DBIO::Introspect::Base`, still overrides only the genuinely MySQL-specific
bits (the four `information_schema` readers, `view_definition`,
`result_class_extra_statements`), and still inherits the generation contract
(`table_keys`, `table_columns`, `table_columns_info`, `table_pk_info`,
`table_uniq_info`, `table_fk_info`, `table_is_view`) from the base. Only the
*file layout* deviates.

## Rationale

The deviation is defensible on this driver's specifics, and recording it is the
house response to a divergence from a documented family decision (surface
conflicts, don't average them).

- The four MySQL readers are unusually tightly coupled: the per-table readers
  (`_build_columns`, `_build_indexes`, `_build_foreign_keys`) are all filtered
  by the same `$tables` hash from `_build_tables`, and they share the
  `column_type` size-parsing and the `_aggregate_by_ordered` grouping. In the
  other drivers the helpers are more independent; here the fan-out bought
  little.
- There is no MariaDB-shaped *sister* introspector planned — MariaDB reads the
  identical `information_schema`, so there is no second adapter to justify a
  per-artifact split for variant override (the comment in `Introspect.pm`
  records exactly this).
- The cross-driver-navigability argument from Sybase ADR 0001 is real, and this
  ADR does **not** dispute it for the family. It documents that MySQL paid that
  navigability cost knowingly, in exchange for keeping four mutually-filtered
  readers in one file.

This is the honest record: the family default is the subdir pattern (Sybase
ADR 0001); MySQL's Introspect is the recorded exception.

## Consequences

- A future architecture review that proposes re-splitting
  `DBIO::MySQL::Introspect` into `Introspect/{Tables,Columns,...}` to "match the
  other drivers" should be weighed against this ADR, not run on autopilot —
  and conversely, a review that proposes collapsing *another* driver's
  Introspect to match MySQL should be sent to Sybase ADR 0001 first.
- If a MariaDB-specific introspection divergence ever appears (a reader that
  must branch on engine), that is the trigger to revisit this decision — a real
  variant override is exactly the case the subdir pattern is built for.
- The Diff subdir helpers stay as they are; this deviation does not extend to
  `DBIO::MySQL::Diff`.
- Whether the family pattern *should* tolerate per-driver exceptions like this
  is a family-level question. It is flagged for the core/family owner via a
  cross-repo karr ticket rather than decided unilaterally here.
