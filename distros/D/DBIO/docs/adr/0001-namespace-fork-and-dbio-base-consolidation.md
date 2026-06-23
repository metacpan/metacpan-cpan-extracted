# ADR 0001 — Namespace fork & DBIO::Base meta-infra consolidation

- Status: accepted
- Date: 2026-06-19
- Tags: architecture, fork, base, backfill

## Context

DBIO is a fork of L<DBIx::Class>. Two structural choices made at the fork
point shape everything downstream and were never written down as a decision —
they are simply baked into the namespace layout and the root base class.

First, the fork is a *hard rename*: the entire `DBIx::Class::*` namespace is
reproduced as `DBIO::*` — every module, test and tool. There is no
`DBIx::Class`-named code left at runtime and no aliasing layer that would let
old `DBIx::Class::*` package names resolve.

Second, DBIx::Class spread its meta-level machinery across several internal
packages (component loading, grouped accessors, MRO setup, attribute caching,
stack-frame skipping). DBIO collapses that machinery into a single root,
`DBIO::Base`, from which every internal class inherits.

## Decision

1. Fork `DBIx::Class` into the `DBIO::` namespace as a **clean break** — there
   is **no runtime `DBIx::Class` compatibility shim**, no namespace alias, no
   `@ISA` bridge. Migration is a mechanical rename plus the targeted API
   updates in `DBIO::Manual::Migration`.
2. Consolidate the meta-infrastructure into `DBIO::Base`
   (`lib/DBIO/Base.pm`), which bundles: `DBIO::Componentised` (the
   `load_components` machinery), `Class::Accessor::Grouped`
   (`mk_group_accessors`), `use mro 'c3'`, the `mk_classdata` /
   `mk_classaccessor` shortcuts, `component_base_class`,
   `MODIFY_CODE_ATTRIBUTES` / `_attr_cache`, and `_skip_namespace_frames`.
   Every internal DBIO class roots here.

## Rationale

A compatibility shim is the expensive default in a fork like this: it pins the
new project to the old project's package names forever, invites code that
loads both ancestries at once, and turns every later divergence into a
two-sided contract. The fork chose the opposite — a single mechanical rename —
so that DBIO's namespace *is* the project, and divergences (SQL::Abstract,
`apply_limit`, the SQLMaker pipeline, native drivers) are free to land without
negotiating against a frozen `DBIx::Class::*` surface. `DBIO::Manual::Heritage`
states this explicitly: "DBIO is a clean break — there is no runtime
`DBIx::Class` compatibility shim."

`DBIO::Base` exists because the meta-infrastructure is what *every* internal
class needs and nothing user-facing should touch. Consolidating it gives one
place to force C3 MRO across the whole tree, one place to wire component
loading, and one root for the `_skip_namespace_frames` data that keeps stack
traces clean. The split between `DBIO::Base` (machinery) and `DBIO.pm` (the
`use DBIO;` sugar) deliberately mirrors the Moose pattern where
`Moose::Meta::*` sits under the hierarchy and `Moose.pm` provides the sugar —
user Result classes inherit through `DBIO::Core`, never `DBIO::Base` directly.

## Consequences

- There is exactly one place — the namespace itself — that defines what DBIO
  is. No code path resolves a `DBIx::Class::*` name at runtime; tooling that
  expects one will not find it.
- Every internal class gets C3 MRO, component loading and grouped accessors by
  inheritance, with no per-class boilerplate. New internal classes root at
  `DBIO::Base`; new user-facing Result classes root at `DBIO::Core`.
- Migration from DBIx::Class is a rename, not a porting exercise — but it *is*
  required; there is no drop-in interop.
- This ADR records the fork's foundational shape. The specific divergences it
  enabled are their own ADRs (see 0002 SQL::Abstract, 0003 `apply_limit`,
  0004 SQLMaker paren-restore + `expand_op`).
