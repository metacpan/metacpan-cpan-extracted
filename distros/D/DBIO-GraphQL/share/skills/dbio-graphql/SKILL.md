---
name: dbio-graphql
description: "DBIO::GraphQL — auto-generate an executable GraphQL schema from a DBIO::Schema. Use when exposing a DBIO schema over GraphQL: queries, filters, pagination, mutations, scalar mapping."
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
use GraphQL::Execution qw(execute);

my $db     = My::Schema->connect(...);        # any connected DBIO::Schema
my $result = DBIO::GraphQL->to_graphql($db);  # class method

# $result = { schema => $graphql_schema, context => $db }
execute($result->{schema}, $query, undef, $result->{context}, \%vars);
```

`to_graphql($db)` returns a hashref: `schema` (pass to `execute`) and `context`
(the original `$db`, used as GraphQL context/root). Composite primary keys are
supported throughout.

## What gets generated

| DBIO thing | GraphQL |
|---|---|
| each source (`$db->sources`) | one `GraphQL::Type::Object` |
| each column | scalar field, typed via `DBIO::GraphQL::ScalarMap::for_column` (`data_type` → Int/Float/Boolean/String) |
| `has_many` | List field |
| `belongs_to` / `might_have` | single object field |
| every source | root `all<Source>s` (plural) + singular lookup |
| every source | `create<X>` / `update<X>` / `delete<X>` mutations |

Incomplete DBIO relationship contracts raise **build-time** errors — see
`DBIO::GraphQL::Relationship`.

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

`createX` / `updateX` / `deleteX` per source — see `DBIO::GraphQL::Mutation`.

## Known behaviour

A plural connection query should always request **at least one scalar field
alongside `nodes`** (e.g. `total`) — see the `KNOWN BEHAVIOUR` section in
`lib/DBIO/GraphQL.pm` POD.

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
