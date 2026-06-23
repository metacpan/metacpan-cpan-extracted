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
  (`lib/DBIO/Manual/Heritage.pod:255-257`). Relationship helpers live in
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

Heritage.pod states the policy (`lib/DBIO/Manual/Heritage.pod:208-212`): "The
following features were previously separate CPAN distributions or required
`load_components`. In DBIO they are part of core and need no explicit loading
unless noted," and the migration table maps each upstream dist to its integrated
DBIO home (`Heritage.pod:579-599`): `DBIx::Class::TimeStamp → DBIO::Timestamp`,
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
