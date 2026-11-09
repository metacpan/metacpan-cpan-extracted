# ADR 0011 — TimeStamp + Helpers integrated into core

- Status: accepted
- Date: 2026-06-19
- Tags: components, timestamp, helpers, backfill

## Context

In DBIx::Class land, several heavily-used component families were *separate* CPAN
distributions that an app installed on top of DBIx::Class and pulled in with
`load_components`: `DBIx::Class::TimeStamp` (auto-populating create/update
datetime columns) and the `DBIx::Class::Helpers` family (Row and ResultSet
helpers, `IntrospectableM2M`). The clean-break fork (ADR 0001) is an opportunity
to stop treating these as optional add-ons and ship the ones DBIO considers
table-stakes in core.

## Decision

Integrate `DBIx::Class::TimeStamp` and the Helper component family directly into
the core distribution, available without a separate install (and, where it makes
sense, without explicit `load_components`).

- **TimeStamp.** `DBIO::Timestamp` (`lib/DBIO/Timestamp.pm`, ABSTRACT at `:2`)
  ships in core: `set_on_create` columns auto-populate on insert, `set_on_update`
  columns refresh on every update, plus the `col_created` / `col_updated` /
  `cols_updated_created` declaration helpers.
- **Helper family.** The Row helpers are folded into `DBIO::Row` (`TO_JSON` /
  `serializable_columns`, `self_rs`, `get_storage_value`, the
  `before_/after_/around_column_change` callbacks) — these come from
  `DBIx::Class::Helper::Row::StorageValues`,
  `DBIx::Class::Helper::Row::OnColumnChange`, and
  `DBIx::Class::Helper::ResultSet::ProxyResultSetMethod`
  (`lib/DBIO/Manual/Heritage.pod`). Relationship helpers live in
  `DBIO::Relationship::Helpers` and its `HasMany`/`HasOne`/`BelongsTo`/
  `ManyToMany` components, with many-to-many introspection (formerly
  `DBIx::Class::IntrospectableM2M`) now automatic via `_m2m_metadata`.

## Rationale

These components are not exotic — they are what most real schemas need on day
one. Shipping them as separate installs was friction inherited from DBIx::Class's
modular packaging, not a design choice DBIO wants to keep. Bundling them in core
means a DBIO schema gets timestamps, JSON serialisation, column-change hooks and
m2m introspection without hunting down extra distributions or matching version
constraints across them.

The integration is deeper than co-shipping in two places worth recording.
TimeStamp is *wired into Cake* (ADR 0010): Cake always loads `DBIO::Timestamp`
so `on_create`/`on_update` and the `col_created`/`col_updated` helpers work out of
the box, and the `timestamp` type function sets the right flags automatically.
And m2m introspection is *automatic* — `_m2m_metadata` is populated without any
explicit `load_components('IntrospectableM2M')`, unlike the upstream opt-in.

Heritage.pod states the policy (`lib/DBIO/Manual/Heritage.pod`): "The
following features were previously separate CPAN distributions or required
`load_components`. In DBIO they are part of core and need no explicit loading
unless noted," and the migration table maps each upstream dist to its integrated
DBIO home (`Heritage.pod`): `DBIx::Class::TimeStamp → DBIO::Timestamp`,
`DBIx::Class::Helpers → DBIO::Row helpers`, `DBIx::Class::IntrospectableM2M →
ManyToMany`, `DBIx::Class::UUIDColumns → DBIO::UUIDColumns`.

## Consequences

- TimeStamp and the Helper family are core capabilities. Apps that loaded the
  upstream dists drop those dependencies; the `load_components` calls for the
  integrated pieces become unnecessary (m2m introspection in particular is now
  automatic).
- The integration is not merely additive: TimeStamp is coupled into the Cake DSL
  (ADR 0010), so changing Timestamp's flags or the `col_created`/`col_updated`
  helpers affects Cake's generated columns — both must be regression-tested
  together (`t/test/10_timestamp_helpers.t` covers Vanilla, Candy and Cake).
- **Scope flag:** the karr ticket names "TimeStamp + Helpers." In code this also
  covers the now-automatic `IntrospectableM2M` and the integrated
  `DBIO::UUIDColumns`, which Heritage lists in the same integrated-components
  table. The decision is the *policy* (fold table-stakes components into core),
  of which TimeStamp and the Helper family are the named instances.
- This is a co-decision with ADR 0001 (the clean break is what permits dropping
  the modular packaging) and ADR 0010 (Cake is the most visible consumer of the
  integrated TimeStamp).

## Addendum 2026-07-26 — the ResultSet helper family

This ADR named only the *Row* helpers (`StorageValues`, `OnColumnChange`,
`ProxyResultSetMethod`) and the relationship helpers. The
`DBIx::Class::Helper::ResultSet::*` family — in particular the
`Helper::ResultSet::Shortcut::*` modules — came in with the same fork commit and
was never recorded here, in `Heritage.pod`, or in `Features.pod`. This addendum
closes that gap and records what an audit of the family found.

### What was integrated

Upstream version: `DBIx::Class::Helpers` 2.037000. All of the following live in
`DBIO::ResultSet` and need no `load_components`:

- **Attribute shortcuts** (`Shortcut::*`) — `columns`, `add_columns`,
  `remove_columns`, `distinct`, `group_by`, `hri`, `rows`, `limit`,
  `limited_page`, `has_rows`, `prefetch`, `order_by` (the `OrderBy` +
  `OrderByMagic` pair, folded into one method).
- **Search shortcuts** (`Shortcut::Search::*`) — `null`, `not_null`, `like`,
  `not_like`, sharing `_helper_meify` / `_helper_apply_search` as upstream does.
- **Existence** (`Shortcut::ResultsExist`) — `results_exist`,
  `results_exist_as_query`, plus the DBIO-only `results_exist_async` (ADR 0031).
- **Standalone helpers** — `me` (`Me`), `correlate` (`CorrelateRelationship`),
  `search_or` (`SearchOr`), `union` / `union_all` / `intersect` /
  `intersect_all` / `except` / `except_all` (`SetOperations`), `one_row`
  (`OneRow`), `no_columns` (`NoColumns`), `bare` (`Bare`), `rand` (`Random`),
  `explain` (`Explain`).

`rand` and `explain` were rebuilt onto storage hooks (`_random_function`,
`_explain_sql`) instead of upstream's `DBIx::Introspector`, per the family's
driver conventions. `page` is the exception in the other direction: upstream's
`Shortcut::Page` was *not* taken and the DBIx::Class core `page` was kept, so it
is the one member of the family that does not route through `search`.

### The consequential difference: opt-in became always-on

Upstream these are components, loaded per ResultSet class. In DBIO they are core
API, always present. That is the policy this ADR records, but it has a
consequence the original decision did not weigh: **a defect in an opt-in helper
reaches only the classes that asked for it, while the same defect in core reaches
every ResultSet in every schema.** Two findings below are exactly that.

It also means upstream's *pairings* are lost. `Helper::ResultSet::SearchOr`
documents that it should be loaded together with
`Helper::ResultSet::IgnoreWantarray`; DBIO folded in `SearchOr` and not
`IgnoreWantarray`, so we shipped the trap without its safety catch. See below.

### Audit outcome (k107)

Every method was diffed against its upstream source. Four outcomes, not three —
the fourth was not anticipated and matters most:

1. **Faithful, and fine.** The majority.
2. **Faithful, but upstream was already wrong.** An *inherited* defect. `order_by`
   was one (fixed in `93061c8cb`); `results_exist` (engine-specific SQL,
   k111), `explain` (bind values passed as `[\%attrs, $value]` pairs) and
   `search_or` are others.
3. **Deliberately changed.** The storage-hook rebuilds, `hri`'s namespace,
   `limited_page`'s `throw_exception`, `correlate`'s dropped version probe.
4. **Broken by the folding itself.** Repaired in `4a94a9025`: `remove_columns`
   was a complete no-op because only the setter was folded in and not the
   `_resolved_attrs` overlay that reads the attribute; `_set_operation` had lost
   its column-compatibility check, so a `union` with transposed columns built
   valid SQL and returned transposed rows; `null`/`not_null`/`like`/`not_like`
   had lost `_helper_meify`, so the leading-dot idiom silently produced
   unqualified, ambiguous predicates; `rows` and `columns` had acquired invented
   getter branches that returned the wrong thing.

The whole family arrived **untested** — `results_exist_async` was the sole
exception. Coverage is being built under `t/helpers/`.

### Deliberately not integrated

- **`IgnoreWantarray`** — not taken, and the gap is real rather than a decision:
  it addresses `search`'s `wantarray`-dependent return type, which DBIO is
  removing wholesale instead (k103 / ADR 0042). Porting it as a component
  would reproduce its own limits — opt-in per class, `search` only, and it
  *replaces* rather than wraps, so it silently skips any other component that
  overrides `search`.
- **`AutoRemoveColumns`** — requires a `remove_column` key in `column_info` that
  DBIO does not have, and the upstream implementation contradicts its own
  documentation (`fetchable_columns` returns the columns to *remove*).
- **`DateMethods1`** — portable date arithmetic via per-engine `isa` chains. That
  is a second, parallel driver-dispatch system next to DBIO's capabilities and
  driver dists. If DBIO ever wants this, it belongs in the drivers as a
  capability plus SQLMaker extension, not folded into core (k114).
- **`Errors`** — an `AUTOLOAD` on the ResultSet for nicer messages. Developer
  comfort against an invasive hook that collides with `can` and with delegation.
- **`ResultClassDWIM`** — the `result_class => '::HRI'` idiom. The common case is
  covered by `hri`; the generic form currently fails with an unusable error
  (k113).
- **`VirtualView`** — upstream-deprecated; its one method wrapped
  `as_subselect_rs`, which DBIO has in core.
- **`Union`** — upstream-deprecated empty subclass of `SetOperations`, which is
  what DBIO took.
- **`Util`** — only exports `correlate` as a function so it can be used without
  loading a component. Moot once everything is always-on.
