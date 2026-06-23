# ADR 0002 — Three-phase build to resolve circular relationship type references

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, type-construction, relationships, architecture, backfill

## Context

The generated schema has one `GraphQL::Type::Object` per DBIO source, and a
relationship field on one source's type points at *another* source's type.
DBIO schemas routinely have circular relationships: `Author` has_many
`Book`, and `Book` belongs_to `Author`. So `Author`'s type must reference
`Book`'s type and vice versa — neither can be fully built before the other
exists.

`GraphQL::Type::Object` supports this through lazy fields: `fields` may be a
coderef that is called later, after all the type objects exist. But laziness
alone is not enough here. `Relationship::build_field` has to resolve a
relationship's *target* type — it looks the target moniker up in a snapshot
of the type table (`$types_snapshot->{$target_moniker}`) and wraps it in a
`GraphQL::Type::List` for plural relations. If that lookup runs while the
type table is still being mutated in the same loop, a relationship could
resolve its target against a type object that is itself mid-construction —
a half-built object whose own `fields` closure has not been installed yet.

The naive single-pass build (create each type and fill its fields in one
loop) hits exactly this: when building source N's fields, sources N+1.. do
not yet exist in the table, so a forward-pointing relationship finds nothing.

## Decision

`DBIO::GraphQL->to_graphql` builds in **three explicit phases**
(`GraphQL.pm`, `to_graphql`):

1. **Phase 1 — shell types.** Create one empty-shell
   `GraphQL::Type::Object` per source, with `fields => sub { {} }`. After
   this loop, *every* source has a stable type object in `%gql_types`, even
   though none has real fields yet.

2. **Phase 2 — fields, against a per-source snapshot.** For each source, take
   a fresh copy of the whole type table at the top of the iteration —
   `my %types_snapshot = %gql_types;` — and install the source's real
   `fields` closure. Scalar columns map via `ScalarMap::for_column`;
   relationships call `$relationship->build_field($source_obj, $rel,
   \%types_snapshot)`, which resolves the target type out of that snapshot.

3. **Phase 3 — roots.** Build the root `Query` and `Mutation` types
   referencing the now-complete per-source types.

The load-bearing detail is that the snapshot is taken **per iteration**, not
once. Because every type object already exists (Phase 1), the snapshot
always contains a usable reference to *every* target type, including ones
later in the loop and the source itself (circular self/mutual refs). A
relationship's target-type lookup therefore never sees a half-built object:
it sees the shell, whose own fields closure resolves lazily and correctly
once the engine walks the graph.

## Rationale

Splitting "make the objects exist" (Phase 1) from "fill the objects in"
(Phase 2) is what makes circular references resolvable. Once all shells
exist, the order in which fields are filled stops mattering: any
relationship can find any target because the target object is already
allocated. The per-iteration snapshot is a closure-capture safety measure —
each source's `fields` coderef closes over its own `%types_snapshot`, so the
lazy field resolution that GraphQL runs later cannot be perturbed by
mutations to `%gql_types` that happen while the rest of the loop runs. This
keeps the mechanism robust under GraphQL.pm's lazy-field model, where the
`fields` sub may be invoked at an arbitrary later point during execution.

The alternative — a single pass with forward declarations patched in
afterwards — would require mutating already-installed field closures and
reasoning about when GraphQL.pm first forces each one. The three-phase
build avoids that entirely: nothing is ever patched after the fact.

## Consequences

- **The shell-first ordering is mandatory.** Any change that fills a type's
  fields before all shells exist, or that resolves a relationship target
  against the live `%gql_types` instead of the captured snapshot,
  reintroduces the half-built-object hazard for circular relationships
  (Author↔Book). New build steps must preserve the phase boundaries.
- The per-source snapshot is a shallow copy of a small hash (one entry per
  source); its cost is negligible and is paid once per source at build time.
- Self-referential relationships (a source pointing at itself) work for free:
  the source's own shell is in its snapshot.
- This mechanism is specific to GraphQL.pm's lazy-field contract. It is
  documented further in the `dbio-graphql-engine` skill (the engine's type
  system and lazy fields); changes to how GraphQL.pm forces `fields` should
  be checked against this build.
