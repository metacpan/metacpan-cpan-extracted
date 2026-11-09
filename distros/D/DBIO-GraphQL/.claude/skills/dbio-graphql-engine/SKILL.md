---
name: dbio-graphql-engine
description: Use when working with the GraphQL.pm engine underneath DBIO::GraphQL — type system, lazy fields, schema construction, execute, resolver contract.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

The `GraphQL` distribution (GraphQL::Perl, by Ed J / ETJ) is the engine
`DBIO::GraphQL` builds on. This skill is the engine-level knowledge for
*extending* `DBIO::GraphQL`; for *using* the generated schema see [[dbio-graphql]].

## Type system building blocks

`DBIO::GraphQL` uses exactly these classes — each `->new(...)`:

| Class | Key constructor args | Builds |
|---|---|---|
| `GraphQL::Type::Object` | `name`, `description`, `fields` | output object type |
| `GraphQL::Type::InputObject` | `name`, `fields` | input type (for args only) |
| `GraphQL::Type::List` | `of => $type` | list/array type |
| `GraphQL::Type::Enum` | `name`, `values => { NAME => { value => ... } }` | enum |
| `GraphQL::Type::NonNull` | `of => $type` | required wrapper |
| `GraphQL::Type::Scalar` | (predefined singletons) | leaf scalars |

**Output vs input is a hard split.** Query/field result shapes are
`GraphQL::Type::Object`; anything used under `args` (filters, pagination,
ordering) must be `GraphQL::Type::InputObject`. Mixing them is an engine error.

## Predefined scalars

`use GraphQL::Type::Scalar qw($Int $String $Boolean);` imports ready-made
scalar singletons (DBIO::GraphQL imports these three; `$Float`, `$ID` exist
too). They are *values*, used directly as a field/arg `type`, e.g.
`{ type => $String }`. Wrap with `GraphQL::Type::NonNull->new(of => $String)`
to make required.

## Lazy fields — the reason for the multi-phase build

A type's `fields` may be a hashref **or a coderef returning a hashref**. The
coderef form is evaluated lazily, which is the only way to express **circular
type references** (A has a field of type B which has a field of type A).

`DBIO::GraphQL::to_graphql` relies on this:

1. Phase 1 — create an empty shell `Object` per source with `fields => sub { {} }`.
2. Phase 2 — replace `->{fields}` with a coderef that closes over a *snapshot*
   of all shells, so a relationship field can reference another source's type
   that may still be half-built in this same loop.

When adding a field whose type is another source's object, resolve it through
that snapshot inside the coderef — never capture a type that is still being
constructed in the current iteration.

## Schema + execution

```perl
my $schema = GraphQL::Schema->new(query => $query_obj, mutation => $mutation_obj);

use GraphQL::Execution qw(execute);
my $data = execute($schema, $query_string, $root_value, $context, \%variables);
```

`query` is required; `mutation` optional; no `subscription` is generated.
`execute` arg order: **schema, query, root, context, variables**. DBIO::GraphQL
passes the connected `DBIO::Schema` as `context`, so every resolver receives it.

## Resolver contract

A field is `{ type => $t, args => {...}, description => ..., resolve => sub {...} }`.

```perl
resolve => sub {
  my ($root, $args, $context, $info) = @_;   # $info rarely needed
  ...
}
```

- `$root` — the parent value (for root Query fields it is the root value).
- `$args` — already coerced to the declared arg types.
- `$context` — here, the `DBIO::Schema` (`$ctx->resultset($moniker)->...`).
- **Return plain Perl data**: a hashref of column→value resolves against an
  Object type's fields; an arrayref of hashrefs resolves a List. DBIO::GraphQL
  returns `{ $row->get_columns }`, not the row object.
- **Errors**: `die` in a resolver — the engine catches it and puts the message
  in the top-level `errors` array, leaving that field `null`. (DBIO::GraphQL's
  create/update mutations rely on this; delete returns `false` instead.)

## Args / coercion

`args => { name => { type => $InputType, description => ... } }`. Scalars and
`InputObject`s only — never an output `Object`. Enum arg values arrive as the
enum's `value`. Nested `InputObject`s arrive as nested hashrefs (that is how
the nested filter shape works).

## Engine quirk to know

A connection/wrapper Object queried with **only** a list sub-field (e.g.
`{ allBooks { nodes { title } } }`) may resolve `nodes` empty in some
`GraphQL::Execution` versions. Always include a scalar sibling
(`total`/`hasNextPage`). This is engine behaviour, not a DBIO bug.

## SEE ALSO

GraphQL::Perl on CPAN (`GraphQL`, `GraphQL::Type::*`, `GraphQL::Execution`),
and the `lib/DBIO/GraphQL.pm` POD for the DBIO-specific mapping.
