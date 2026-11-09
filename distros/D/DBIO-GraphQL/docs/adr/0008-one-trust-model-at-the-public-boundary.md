# ADR 0008 — One trust model at the public boundary

- Status: accepted
- Date: 2026-10-30
- Tags: graphql, security, authorization, trust-model, mutations, introspection

## Context

`to_graphql` turns a DBIO schema into a GraphQL API. The result is reachable
by any client that can send a query, so everything the generator releases is
public surface: sources, columns, relationships, mutations and the schema
description itself. The generator has no knowledge of the application's users,
roles or tenants, and cannot have: those belong to the application in front of
it.

The distribution therefore needs one stated rule for what the generated API
is, who decides what it releases, and where the application's authorization
plugs in.

## Decision

**The generated API is full access to what `to_graphql` releases; the caller of
`to_graphql` decides what is released, and the application's authorization runs
in a hook the generator calls before it touches the database.**

The rule has five parts, all carried by `DBIO::GraphQL::Policy`, which Filter,
Mutation, Relationship and `DBIO::GraphQL` ask instead of deciding on their
own:

1. **Documented at the top.** README and POD state that, without an
   authorization layer of its own in front of it, the API is full access to
   what `to_graphql` releases.
2. **Exposure is chosen.** `sources` or `except` select the exposed sources
   (not both). A source that is left out is gone entirely, including as the
   target of another source's relationship field. `hide` takes columns out of
   the schema, the filters, the ordering and the mutations; a column declared
   `is_serializable => 0` is hidden without being named. `readonly` keeps
   columns readable but never a mutation argument. Primary keys remain the
   identity of get, update and delete; `readonly` on a primary key forbids
   only setting it on create. A hidden or readonly unique-constraint column is
   not a lookup argument.
3. **Mutations are opt-in.** `mutations => 1` for every exposed source or a
   list of sources. Without the option the schema has no `Mutation` type.
4. **Authorization is a hook.** `authorize => sub { my ($op, $moniker, $args,
   $context, $relationship) = @_ }` runs before every resolver that touches the
   database: the root queries (`get`, `list`), the mutations (`create`,
   `update`, `delete`), relationship fields (`relationship`, with the target
   source and the relation name) and the count of a plural query. A false
   answer fails the field with "not authorized" before any SQL. A true answer
   allows. A hashref allows with a restriction:
   - reads (`get`, `list`, `relationship`, `total`): ANDed into the search, in
     front of the lookup of the row, of the related rows and of the count;
   - `update` and `delete`: part of the writing statement itself
     (`search($restriction)->search($pk)->update`), so the statement touches no
     row outside it; a miss is "not found" for update and `false` for delete;
   - `create`: its equality values are set as column values, and a different
     value from the client is an error (the client does not choose what the
     policy fixes, core k381). A value that is not an equality cannot be
     applied to a create and is an error.
5. **Introspection is switchable.** `introspection => 0` refuses `__schema` and
   `__type`. The engine resolves both meta fields itself and has no switch, so
   the refusal is `DBIO::GraphQL->check_document($result, $query)`, run on the
   query document before `execute`. The default is on.

`to_graphql` rejects an option it does not know and a source or column an option
names that does not exist, so a mistyped option never silently releases more.

## Rationale

A generator can release only what it is told to release, and the caller is the
only party that knows the application. Putting the choice into `to_graphql`'s
options keeps it in one reviewable place; the default stays the documented full
access, and every narrowing is an explicit option. One policy object that all
building blocks ask means a column hidden once is hidden in the type, the
filter, the ordering and the mutations alike, instead of five places agreeing
by convention.

The hook is placed before the resolver's first database access rather than
after the data is read, which makes "not authorized" cost no SQL, and it returns
a restriction rather than only a verdict so that row-level rules (tenants,
ownership) are one hashref and are enforced inside the statement that reads or
writes, not by a second lookup that could disagree with it.

## Consequences

- The default behaviour changed in one place: a schema without `mutations` has
  no `Mutation` type. Code and tests that use mutations pass `mutations => 1`.
- `DBIO::GraphQL::Policy` is the single place that answers visibility,
  writability and authorization. A new resolver or building block asks it
  before it touches the database.
- ADR 0004's Filter and Mutation seams are unchanged: `to_graphql` still
  instantiates `Filter::Search` itself; it now hands every building block the
  policy.
- `introspection => 0` is only as strong as the call to `check_document`; a
  caller that runs `execute` on an unchecked document still serves
  introspection. A wrapper around `execute` that performs the check is a
  separate piece of work.
- The `authorize` hook decides per operation and per source; it does not see
  individual rows of a list. Row-level rules are expressed as the restriction
  it returns.

## Addendum 2026-10-30 — result sets are bounded (karr k16)

What a client may ask for is bounded by the same boundary. The caller of
`to_graphql` sets `default_rows` (rows without `page`/`cursor`, also the cap of
a `has_many` field), `max_rows` (`take`, `first`, `skip`) and `max_in` (values of
an `in` filter; `default_rows` may not exceed `max_rows`, `to_graphql` dies); `DBIO::GraphQL::Policy` holds them. An excess is an error before
any SQL, never a silent cut, so a client never receives less than it asked for
without being told. The COUNT behind `total` runs only when `total` is selected;
the `list` authorization stays the single call that guards it.

## Addendum 2026-10-30 — the document is checked before it runs (karr k15)

The boundary also decides how much work one request may ask for, and it
decides that before the first SQL, on the parsed document. `to_graphql` returns
an `execute` code reference as the entry point; it runs `check_document`
(`introspection => 0`) and `DBIO::GraphQL::Limits` on the AST and then calls
the engine. The rule has four parts:

1. **Fragment cycles are refused** before unfolding, in every fragment of the
   document (the engine has no such rule).
2. **`max_depth`** (default 10) bounds the selection depth after unfolding
   fragments; the relationship resolvers also check the depth from the path of
   the resolve info, so a schema executed without `execute` is depth-bounded.
3. **`max_cost`** (default 10000, so a full `max_rows` page with a few fields and a
   `has_many` level of `default_rows` x `default_rows` fit) bounds the cost: every field costs 1, aliases
   one by one, each spread of a fragment costs its fields again. Fields that
   yield rows -- a plural query with its connection object, a `has_many`
   field -- multiply what is below them by their page size (`page.take`,
   `cursor.first`, variables and defaults resolved, else `default_rows`).
4. **Depth, cost and the bounds of the result sets** (`default_rows`,
   `max_rows`, `max_in`) together bound a request. The promise holds for
   `execute`; executing `schema` directly skips the document check.

The introspection switch of this ADR is now enforced by `execute` itself;
`check_document` stays as the same check for a caller with its own entry point.
