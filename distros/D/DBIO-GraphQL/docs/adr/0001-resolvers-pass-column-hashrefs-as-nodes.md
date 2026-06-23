# ADR 0001 — Resolvers pass column hashrefs as nodes, not live DBIO rows

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, resolver, architecture, fork, backfill

## Context

DBIO::GraphQL is a DBIO port of MANWAR's L<DBIx::Class::Schema::GraphQL>
(see the POD ACKNOWLEDGEMENTS in `lib/DBIO/GraphQL.pm`). The natural,
faithful port resolves every GraphQL field against a live ORM row: the
node value handed to the GraphQL engine *is* a `DBIO::Row`, and each scalar
or relationship field is satisfied by calling the corresponding accessor on
that live object. That is how the upstream DBIC implementation works, and it
is the obvious shape for a GraphQL-over-ORM layer.

This distribution diverges at that exact point. Every resolver in the
generated schema returns a **plain column hashref** — `{ $row->get_columns }`
— as the GraphQL node, and never the live row object. This is visible in
all four resolver sites:

- the singular query resolver (`GraphQL.pm`, `to_graphql`, the
  `$query_fields{ lcfirst($moniker) }` resolver) returns
  `$row ? { $row->get_columns } : undef`;
- the plural / connection path materialises nodes as
  `[ map { { $_->get_columns } } @rows ]` (`_apply_pagination`);
- the mutation resolvers (`Mutation.pm`, `build_create` / `build_update`)
  return `{ $row->get_columns }`;
- the relationship resolver (`Relationship.pm`, `build_field`) returns
  `{ $related->get_columns }` for a single relation and
  `[ map { { $_->get_columns } } ... ]` for a plural one.

The node a GraphQL resolver returns is the parent value its child resolvers
receive. Because the node is a detached hashref, no child resolver can call
a DBIO accessor — there is no live row to call it on. The decision is
foundational: it constrains every field type the schema can grow.

## Decision

The GraphQL node is a **detached column hashref**, never a live DBIO row.
Every resolver materialises its return value with `{ $row->get_columns }`
(or a list of them) at the boundary, and downstream resolvers operate on
that hashref.

Where a child resolver genuinely needs the row back — relationship
traversal — it **re-finds the row by primary key** rather than keeping a row
reference alive. `DBIO::GraphQL::Relationship::build_field`'s resolver
detects a hashref parent (`if (ref($row) eq 'HASH')`) and calls
`_pk_find($ctx, $moniker, $row)` (`Relationship.pm`, the `_pk_find` helper),
which reads the source's `primary_columns`, pulls the PK values out of the
hashref, and issues a fresh `$ctx->resultset($moniker)->find(...)`. Only then
does it traverse `$row->$rel_name`.

## Rationale

A live-row node couples the GraphQL object graph to ORM row lifetime,
identity, and the surrounding transaction/connection. A detached hashref is
a flat, serialisable value with no hidden DB I/O behind its fields: a scalar
field read is a hash lookup, not a lazy accessor that might touch the
database. That makes the node boundary explicit — the row is read once, at
the resolver that produced it, and everything downstream is plain data. It
also makes the schema's behaviour uniform: a node coming from a top-level
query, from a relationship hop, or from a mutation return all look identical
to child resolvers, so field resolution never has to care where its parent
came from.

The cost — a relationship hop must re-find its parent row by PK — is paid
deliberately and locally in `Relationship.pm`, rather than smeared across the
schema as an implicit dependency on live-row state. Re-finding by PK is
correct for any source with a primary key (the universal case here) and
keeps the relationship resolver self-contained.

## Consequences

- **`Relationship.pm` must re-find the row by PK before every traversal.**
  `_pk_find` issues one `find()` per relationship resolution. A relationship
  hop is therefore an extra point lookup, not a cheap pointer-follow on an
  in-memory row. This is the direct, accepted cost of detached nodes.
- **N+1 is structural, not incidental.** Because each relationship resolution
  re-finds its parent and then loads the relation, a nested query fans out
  into per-node lookups. Any future N+1 optimisation (batching / dataloader /
  prefetch) must work *with* the hashref-node model — e.g. by batching the
  `_pk_find` lookups or carrying prefetch results in the hashref — not by
  reverting to live-row nodes.
- **Every future field type inherits this constraint.** New field kinds
  (computed fields, aggregates, deeper relationship shapes) get a hashref as
  their parent value and must either be satisfiable from columns already in
  the hashref or re-find what they need. There is no live row to lean on.
- A source with no usable primary key cannot have its relationships traversed
  through this path: `_pk_find` returns nothing when a PK value is missing,
  and the relationship resolves to empty/undef.
