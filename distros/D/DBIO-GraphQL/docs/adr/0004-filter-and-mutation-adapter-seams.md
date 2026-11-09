# ADR 0004 — Filter adapter seam (Search/Null) and mutation builder seam

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, adapter, seam, extensibility, filter, mutation, backfill

## Context

Two parts of the generated schema are obvious future extension points:

- **Filtering.** A deployment might want the default nested-per-column filter
  (ADR 0003), a stricter/looser filter, or no filtering at all. Hard-wiring
  the filter behaviour into `to_graphql` would make any of these a fork of
  the generator.
- **Mutations.** `createX` / `updateX` / `deleteX` are generated for every source that opted in (ADR 0008),
  but real applications often need variants: a soft-delete that flips
  a flag instead of issuing `DELETE`, an audited create that records who/when,
  a variant of the update semantics. Inlining all three
  mutation builders as one monolithic method would make any one variant
  require rewriting the others.

The decision is to invest in **adapter / override seams** for both, up front,
even though the distribution currently ships only the default behaviours.

## Decision

### Filter adapter interface

`DBIO::GraphQL::Filter` is an **adapter base class** defining a two-method
contract (`Filter.pm`):

- `type_for($moniker)` — return the GraphQL filter InputObject for a source.
- `to_search($args, $moniker)` — translate filter args into a DBIO search
  condition (or `undef`).

Two concrete adapters ship:

- **`DBIO::GraphQL::Filter::Search`** (default) — inherits the full
  nested-per-column behaviour from the base (`Filter/Search.pm` is a thin
  subclass; `to_graphql` instantiates it, hard-wired).
- **`DBIO::GraphQL::Filter::Null`** — a real no-op adapter (`Filter/Null.pm`)
  that overrides `type_for` to return an **empty** `${moniker}Filter`
  InputObject (no per-column fields, no `AND`/`OR`) and `to_search` to always
  return `undef`.

`Null` is deliberately *not* dead code: it proves the seam is real, because
it produces both a **different GraphQL surface** (an empty filter type, so the
schema a client introspects genuinely changes) *and* different DBIO behaviour
(no search condition is ever applied) for the same source moniker. A seam that
only one implementation can satisfy is not a seam; `Null` is the second
implementation that demonstrates the contract holds.

### Mutation builder seam

`DBIO::GraphQL::Mutation` splits its work so each mutation kind is its own
overridable method (`Mutation.pm`): `fields_for` dispatches to `build_create`,
`build_update`, and `build_delete` separately. A subclass can override exactly
one kind — e.g. a SoftDelete variant overriding only `build_delete`, an Audit
variant wrapping `build_create`, a variant replacing `build_update` — without touching or duplicating the other two. The shared
helpers (`_scalar_for`, `_col_is_required`, `_build_lookup_args`,
`_resolve_row`) are likewise individually overridable.

## Rationale

Both seams are the cheap, principled way to absorb known-likely variation
without forking the generator. For filtering, the adapter interface
is the class-level seam for swapping the filter strategy, with the base
class carrying the default so the common case stays zero-config. Today
`to_graphql` takes no adapter argument and instantiates
`DBIO::GraphQL::Filter::Search` itself, so handing it another adapter
needs a change to `to_graphql`. Shipping `Null` alongside `Search` is what keeps the interface
honest: it forces the contract (`type_for` + `to_search`) to be genuinely
sufficient to express "no filtering" as well as "full filtering", and it is
the second implementation of the contract. No test exercises it yet; until
one does, the seam's claim rests on `Null` compiling and implementing the
two methods.

For mutations, one-method-per-kind is the minimal structure that makes the
two anticipated variants (SoftDelete / Audit) single-method
overrides instead of full rewrites. It does not add an abstraction layer or a
registry — it just declines to fuse three independent builders into one
method.

## Consequences

- **The `Null` adapter is intentional and must not be removed as "unused".**
  It is the existence proof for the Filter seam (currently untested and not
  reachable from `to_graphql`). Deleting it would silently collapse the
  seam back to a single hard-wired strategy.
- New filter strategies subclass `DBIO::GraphQL::Filter` and implement
  `type_for` / `to_search`; wiring one in
  requires `to_graphql` to accept it, which it does not yet.
- New mutation variants subclass `DBIO::GraphQL::Mutation` and override a
  single `build_*` method; the other kinds and all shared helpers are
  inherited unchanged.
- This is a deliberate extensibility investment made ahead of a concrete
  second consumer. It is justified by the explicit, named set of expected
  variants and by the no-op adapter that keeps the seam exercised today.
