# DBIO-GraphQL

Auto-generate a [GraphQL](https://metacpan.org/pod/GraphQL) schema from a
[DBIO](https://metacpan.org/pod/DBIO) schema.

`DBIO::GraphQL->to_graphql($schema)` introspects every source registered with a
connected `DBIO::Schema` and returns an executable `GraphQL::Schema` with:

- One scalar field per column, typed from the column's `data_type`
  (`Boolean` for `bool*`/`tinyint(1)`, `Float` for `decimal`/`numeric`/...,
  `Int` for the rest of the integer family, `String` otherwise).
- One relationship field per DBIO relationship (`has_many` → list,
  `belongs_to`/`might_have` → single object). Build-time errors are emitted
  when the DBIO `relationship_info` contract is incomplete.
- A root `Query` type with singular lookups and plural `allXs` queries
  supporting nested per-column filtering, ordering, and offset/cursor
  pagination.
- A root `Mutation` type with `createX`, `updateX`, `deleteX` per source.

Composite primary keys are supported throughout.

## Synopsis

```perl
use DBIO::GraphQL;
use GraphQL::Execution qw(execute);

my $db     = My::Schema->connect(...);
my $result = DBIO::GraphQL->to_graphql($db);

# Plural query with nested-DBIO-style filter
execute($result->{schema}, '
  query {
    allBooks(
      filter:  { title: { like: "%Perl%" } }
      orderBy: { field: "title", direction: ASC }
      page:    { skip: 0, take: 5 }
    ) {
      total nodes { id title }
    }
  }', undef, $result->{context});
```

See the module POD (`perldoc DBIO::GraphQL`) for the full query/mutation
surface, filtering operators, pagination, limitations, and known behaviour.

## Architecture

`DBIO::GraphQL` is a thin orchestrator over four focused modules:

- `DBIO::GraphQL::ScalarMap` - column `data_type` → GraphQL scalar
- `DBIO::GraphQL::Filter` (and `::Search`, `::Null` adapters) -
  per-source GraphQL `InputObject` translating nested filter args into
  DBIO search conditions
- `DBIO::GraphQL::Relationship` - relationship field resolution with
  strict contract validation (closes KARR #1)
- `DBIO::GraphQL::Mutation` - `createX` / `updateX` / `deleteX` per source

Each module is independently testable through its own public interface.

## Acknowledgements

DBIO port of
[DBIx::Class::Schema::GraphQL](https://metacpan.org/pod/DBIx::Class::Schema::GraphQL)
by Mohammad Sajid Anwar (MANWAR). The original `DBIx::Class` implementation,
design, and documentation are his work; this distribution adapts them to the
`DBIO` schema introspection API and re-architects the filter surface into
a nested per-column shape that mirrors DBIO's native search-condition format.
