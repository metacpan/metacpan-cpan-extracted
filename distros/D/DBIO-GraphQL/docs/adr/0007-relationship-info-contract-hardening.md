# ADR 0007 — Relationship contract hardening: relationship_info keys treated as a stable contract

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, relationships, contract, hardening, core-dependency, backfill

## Context

`DBIO::GraphQL::Relationship` builds a GraphQL relationship field by reading
two keys out of `$source->relationship_info($rel)`:

- `->{source}` — the target Result class, used to find the target GraphQL
  type in the type snapshot;
- `->{attrs}{accessor}` — `'multi'` for `has_many` (resolves to a `List`),
  anything else for a single-object relation.

These keys are **undocumented internals** of DBIO's source metadata, inherited
from the DBIx::Class introspection API. Before this hardening, the build loop
read them defensively-by-omission: a relationship whose `source` was missing,
or whose target moniker was not present in the type snapshot, was simply
**skipped** (`or next`) — no error, no warning. A future core change to
either key, or to their shape, would have made relationships **vanish from the
generated schema silently**, with no signal that a dependency had broken.

This was raised as **karr #1** (filed 2026-06-09, low priority) — a hardening
item, not a blocker — which called for: clear build-time errors naming the
relationship, documenting the exact `relationship_info` contract dbio-graphql
relies on, and (explicitly scoped as a *separate core ticket*) optionally
asking core to promote these keys to a documented-stable public contract.

## Decision

The two `relationship_info` keys are treated as a **locally documented-stable
contract**, and their absence is a **loud, build-time failure** rather than a
silent drop (`Relationship.pm`; landed in commit `dfc1624`):

- `build_field` validates the contract explicitly: it `_fail`s with a message
  **naming the relationship and the source** when `->{source}` is undefined,
  when `->{attrs}` is not a hash with an `accessor` key, or when the resolved
  target type is absent from the type snapshot.
- `_fail` honours an **`on_error`** mode set at construction: the default
  `'die'` raises the error (a broken contract stops the build); `'warn'`
  downgrades it to a warning and returns `undef` so the caller skips just that
  one relationship. `on_error` is the deliberate escape hatch — it preserves
  the old skip-and-continue behaviour, but only as an explicit, opted-into
  choice, never as the silent default.
- The contract is documented in the module header and the POD ERROR HANDLING
  section, so a future core change surfaces as a tracked dependency.
- Test coverage: **`t/07-relationship-contract.t`** exercises the die paths
  (missing `source`, missing `accessor`, target absent from snapshot), the
  `warn`-path skip, and the plural/singular happy paths.

This ADR records **only the dbio-graphql-side hardening**. Whether core
promotes `relationship_info()`'s `{source}` and `{attrs}{accessor}` to a
documented-stable *public* contract is a **core-owned decision** and is filed
as a separate cross-repo karr ticket against `dbio` (karr #1 explicitly scoped
it out as such). It is not an ADR here.

## Rationale

A silent skip is the worst failure mode for a generated schema: the schema
still builds, still executes, and simply lacks fields the caller expected —
the kind of breakage that is discovered in production, far from its cause. A
fork that depends on undocumented internals of the upstream metadata API must
make that dependency *visible*, so the right response to the keys disappearing
is a build-time error that names exactly which relationship on which source
broke, pointing straight at the contract that changed.

`on_error => 'warn'` exists because some callers genuinely prefer a degraded
schema over a hard stop (e.g. a source with one malformed relationship among
many). Making that a per-instance choice keeps the *default* strict while
still supporting graceful degradation — the difference from before is that
degradation is now opt-in and audible (a warning), not silent.

Keeping the core-side promotion out of this ADR respects repo ownership: the
shape and stability guarantees of `relationship_info()` belong to `dbio`, not
to this consumer. dbio-graphql can harden against the keys locally and
document the contract it depends on; it cannot unilaterally declare core's
internal API stable.

## Consequences

- A broken `relationship_info` contract now fails **loudly at build time**,
  naming the relationship and source — no more vanishing relationship fields.
- Callers that want the old lenient behaviour pass `on_error => 'warn'` and
  get warn-and-skip; the strict `'die'` default protects everyone else.
- `t/07-relationship-contract.t` pins the contract: a change to which
  `relationship_info` keys are required, or to the error behaviour, must
  update this test, which keeps the dependency honest.
- The cross-repo dependency on core is now explicit. If core promotes
  `{source}` / `{attrs}{accessor}` to a documented public contract (see the
  cross-repo karr ticket filed against `dbio`), this local hardening becomes a
  guard against a *stable* surface rather than an *undocumented* one — the
  code does not need to change, only its risk profile improves.
