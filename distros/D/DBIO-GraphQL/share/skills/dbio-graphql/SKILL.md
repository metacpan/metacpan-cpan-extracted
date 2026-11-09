---
name: dbio-graphql
description: Use when exposing a DBIO schema over GraphQL — queries, filters, pagination, mutations, scalar mapping.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO::GraphQL introspects a connected `DBIO::Schema` and builds a complete,
executable `GraphQL::Schema` — one type per source, scalar + relationship
fields, root Query and Mutation. Pure-Perl/CAG conventions → [[dbio-perl-syntax]].

## Entry point

```perl
use DBIO::GraphQL;

my $db     = My::Schema->connect(...);        # any connected DBIO::Schema
my $result = DBIO::GraphQL->to_graphql($db);  # class method

# $result = { execute => sub {...}, schema => $graphql_schema, context => $db }
$result->{execute}->($query, undef, $result->{context}, \%vars);
```

`to_graphql($db)` returns a hashref: `execute` (the entry point: checks the
document for fragment cycles, `max_depth`, `max_cost` and `introspection`, then
runs the engine), `schema` and `context` (the original `$db`, used as GraphQL
context/root). Executing `schema` directly skips the document check. Composite primary keys are
supported throughout.

## What gets generated

| DBIO thing | GraphQL |
|---|---|
| each source (`$db->sources`) | one `GraphQL::Type::Object` |
| each column | scalar field, typed via `DBIO::GraphQL::ScalarMap::for_column` (`data_type` → Boolean/Float/Int/String; bigint, bigserial, decimal, numeric and money are String, since GraphQL Int is 32-bit; a bigint key is a String id) |
| `has_many` | List field |
| `belongs_to` / `might_have` | single object field |
| every source | root `all<Source>s` (plural) + singular lookup |
| source named in `mutations` | `create<X>` / `update<X>` / `delete<X>` mutations (opt-in) |

Incomplete DBIO relationship contracts raise **build-time** errors — see
`DBIO::GraphQL::Relationship`.

## Trust model — options of `to_graphql`

The caller of `to_graphql` decides what a client may see, change and cost
(ADR 0008, `SECURITY.md`):

- `sources => [...]` or `except => [...]` (not both): which sources exist; a
  left-out source is gone, also as relationship target.
- `hide => { Source => [cols] }`: out of schema, filters, ordering, mutations
  (`is_serializable => 0` hides without naming). `readonly => {...}`: readable,
  never a mutation argument.
- `mutations => 1 | [Sources]`: mutations exist only when named.
- `authorize => sub { my ($op, $moniker, $args, $context, $relationship) = @_ }`:
  runs before every database-touching resolver (`get list create update delete
  relationship`). False dies `not authorized` before SQL; a hashref allows and
  restricts (ANDed into reads/counts, part of UPDATE/DELETE, column values of a
  create).
- `introspection => 0`: `__schema` / `__type` refused by `execute`.
- Bounds, each a positive integer, an excess is an error before SQL:
  `default_rows` (100; rows without page/cursor and cap of a `has_many` field,
  at most `max_rows`, else `to_graphql` dies), `max_rows` (1000; `take`, `first`,
  `skip`), `max_in` (500; values of `in`), `max_depth` (10), `max_cost` (10000;
  fields x page sizes). `total` runs its COUNT only when selected.

Queries go through `$result->{execute}`, which checks the document first
(fragment cycles, depth, cost, introspection) and answers a refused one with
`{ errors => [...] }`.

## Queries — filter, order, paginate

Filter shape mirrors the nested DBIO search-condition format (see
`DBIO::GraphQL::Filter` / `Filter::Search`):

```graphql
allBooks(
  filter:  { title: { like: "%Perl%" } }
  orderBy: { field: "title", direction: ASC }
  page:    { skip: 0, take: 5 }
) { total hasNextPage nodes { id title } }
```

Cursor (Relay-style) pagination is also supported:

```graphql
allBooks(cursor: { after: $after, first: 5 }) {
  total nextCursor hasNextPage nodes { id title }
}
```

## Mutations

```graphql
mutation { createBook(title: "Dune", author_id: 4) { id title } }
```

`createX` / `updateX` / `deleteX` per source named in `mutations` — see `DBIO::GraphQL::Mutation`.

## Internals (for extending)

| Module | Role |
|---|---|
| `DBIO::GraphQL::ScalarMap` | column `data_type` → GraphQL scalar |
| `DBIO::GraphQL::Filter` / `::Filter::Search` / `::Filter::Null` | filter arg → DBIO search cond |
| `DBIO::GraphQL::Relationship` | relationship → field, contract validation |
| `DBIO::GraphQL::Mutation` | create/update/delete builders |

## Dependencies & testing

- Runtime: `GraphQL` (perl-graphql) + `GraphQL::Execution`. A DBIO driver to
  connect against (tests use `DBIO::SQLite`, `dbi:SQLite:dbname=:memory:`).
- Tests: deploy a schema, create rows, call `to_graphql`, run `execute`. See
  `t/03-queries.t`, `t/04-mutations.t`, `t/05-composite-pk.t`,
  `t/06-pagination-filter.t`.
