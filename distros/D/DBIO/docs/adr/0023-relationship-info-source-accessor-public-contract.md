# ADR 0023 — `relationship_info()` `{source}` and `{attrs}{accessor}` are a public contract

- Status: accepted
- Date: 2026-06-22
- Tags: public-api, relationship, introspect, contract, cross-repo

## Context

`relationship_info($rel_name)` (`lib/DBIO/ResultSource.pm`) returns a hashref of
relationship metadata, inherited largely unchanged from the DBIx::Class
introspection API. Two of its keys had become de-facto load-bearing for a
downstream consumer while remaining formally undocumented internals:

- `{source}` — the fully-qualified target Result class of the relationship.
- `{attrs}{accessor}` — the relationship arity marker (`'multi'` for `has_many`).

`dbio-graphql` reads exactly these two keys to build its relationship fields:
`DBIO::GraphQL::Relationship` uses `{source}` to find the target GraphQL type and
treats `{attrs}{accessor} eq 'multi'` as the plural/List cardinality, single
otherwise (`dbio-graphql/lib/DBIO/GraphQL/Relationship.pm:60,70`). It had already
hardened on its own side — a build-time error naming the relationship/source when
either key is missing, rather than silently dropping the field (commit
`dfc1624`) — and recorded that hardening in **dbio-graphql ADR-0007**, which
deliberately deferred the *core* question to a separate core ticket. That ticket
is core karr **#51** (`from:dbio-graphql`): a downstream consumer cannot
unilaterally declare core internals stable, so it asked core to either bless the
keys or name a supported alternative.

Empirically, against `DBIO::Test::Schema`, the keys are present for every
relationship kind, and the arity marker takes these values:

| relationship | `{attrs}{accessor}` |
|---|---|
| `has_many`   | `multi`  |
| `belongs_to` | `filter` |
| `has_one` / `might_have` | `single` |

So the single-value side is **not** a single literal — `belongs_to` is `filter`,
not `single`. The only reliable cut is `multi` versus not-`multi`, which is
exactly what `dbio-graphql` already keys on.

## Decision

Accept. `{source}` and `{attrs}{accessor}` are promoted to a **documented,
stable, public part of the `relationship_info()` return contract**. Downstream
consumers may depend on them without guarding against silent disappearance.

1. Both keys are documented in the `relationship_info` POD
   (`lib/DBIO/ResultSource.pm`): `{source}` is the fully-qualified target Result
   class regardless of arity; `{attrs}{accessor}` is the arity marker.
2. The contractual arity distinction is **`multi` versus not-`multi`**: `'multi'`
   denotes a `has_many` (resultset of zero-or-more rows); anything else denotes a
   single-value relationship. The specific single-side spellings (`filter` for
   `belongs_to`, `single` for `has_one`/`might_have`) are reported accurately in
   the POD but are **not** themselves contractual — a consumer must test for
   `multi`, never enumerate the single-side values.
3. Changes to either key are henceforth treated as **public-API changes**
   (deprecation path, not silent breakage).
4. A mock-only regression test (`t/relationship_info_contract.t`) locks the
   contract so it fails loudly if it ever regresses.

The remaining keys of `relationship_info()` stay unblessed internals; this ADR
promotes only these two.

## Rationale

The keys are inherited from a stable upstream introspection API and are already
relied upon by a real, shipped consumer. Promoting them changes no runtime
behavior — it converts a silent-breakage risk into a guarded, documented
contract for the cost of POD plus one test. Documenting the accurate
`multi`-versus-not-`multi` cut (rather than the looser "single otherwise" that
the downstream comment uses) keeps a future consumer from over-fitting to
`single` and breaking on a `belongs_to`'s `filter`.

Core owns the contract because `relationship_info()` is core's public surface; a
cross-repo consumer cannot bless core internals from the outside. This is the
same ownership principle as ADR 0018 — a contract that spans repos is decided
once, in the repo that owns the method — applied here as straightforward
public-API stewardship rather than a family-policy realignment.

## Consequences

- **dbio-graphql karr #1 / ADR-0007 are satisfied.** Its defensive build-time
  guards may stay (belt-and-suspenders) but no longer rest on undocumented
  internals; the keys are now a contract core commits to.
- **The arity cut is `multi` vs not-`multi` only.** The single-side spellings
  (`filter`, `single`) are documented for accuracy but are not contractual;
  consumers test for `multi`.
- **Future changes to `{source}`/`{attrs}{accessor}` are public-API changes** and
  follow a deprecation path, not silent removal.
- `t/relationship_info_contract.t` (mock-only) is the regression guard.
- Other `relationship_info()` keys remain internal and unpromised.

Relates to ADR 0018 (family-policy/ownership pattern), and to dbio-graphql
ADR-0007, dbio-graphql karr #1, and core karr #51.
