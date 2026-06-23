# ADR 0003 — Filter surface re-architected to a nested per-column shape

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, filter, fork, search-conditions, backfill

## Context

DBIO::GraphQL is a DBIO port of MANWAR's L<DBIx::Class::Schema::GraphQL>.
The POD ACKNOWLEDGEMENTS in `lib/DBIO/GraphQL.pm` credit MANWAR's original
design and documentation, then explicitly state that this distribution
"re-architects the filter surface into a nested per-column shape that mirrors
DBIO's native search-condition format." The filter surface is the one place
the fork deliberately walks away from the upstream design rather than porting
it mechanically.

The GraphQL caller needs to express column predicates (equality, ranges,
membership, substring match, null tests) and boolean combinations of them.
DBIO's native search condition is already a nested hashref of the form
`{ col => { op => value }, ... }` with `-and` / `-or` combinators. The
re-architecture chooses a GraphQL input shape that mirrors that format
1:1, so translation is a structural walk rather than a query-language
reinterpretation.

## Decision

Filtering is expressed as a **nested per-column input shape** with recursive
combinators, compiled to native DBIO search conditions (`Filter.pm`).

- **Per-scalar `*Filter` InputObjects.** Each GraphQL scalar gets one shared,
  class-level-memoized operator InputObject: `IntFilter`, `FloatFilter`,
  `StringFilter`, `BoolFilter` (`Filter::_scalar_input`, `_ops_for`). A
  column's filter field is typed by mapping the column to a scalar
  (`ScalarMap::for_column`, see ADR 0006) and using that scalar's `*Filter`.
- **Nested per-column shape.** The per-source `${moniker}Filter` InputObject
  (`Filter::type_for`) has one field per column whose type is the column's
  `*Filter`, e.g. `{ title: { like: "%Perl%" }, author_id: { gt: 3 } }`.
- **Recursive AND/OR.** `type_for` adds `AND` and `OR` fields, each a list of
  the same `${moniker}Filter` type (a forward-declared self-reference via the
  lazy `fields` sub), so combinators nest arbitrarily.
- **Compiled to native conditions.** `to_search` / `_compile` /
  `_compile_column` walk the input and emit a DBIO search hashref: `gt`→`>`,
  `lt`→`<`, `in`→`-in`, `eq`→the bare `col => val` form, `isNull`→
  `col => undef` or `col => { '!=' => undef }`, and `AND`/`OR`→`-and`/`-or`.
- **`contains` / `startsWith` / `endsWith` are wrapped LIKE, not new DBIO
  operators.** The `String` operator spec gives these three a `wrap` coderef
  that decorates the value with SQL wildcards (`'%'.$v.'%'`, `$v.'%'`,
  `'%'.$v`) and emits `{ like => ... }` (`Filter._ops_for`, the `String`
  entry; applied in `_compile_column` via `$spec->{wrap}`). No new operator
  is introduced into the DBIO condition vocabulary.

## Rationale

Mirroring DBIO's native search-condition format means the compiler is a
mechanical, recursive structural transform — there is no separate filter
expression language to parse, validate, or keep in sync with DBIO's operator
set. Per-scalar `*Filter` InputObjects keep the GraphQL surface
self-documenting (an `Int` column offers `gt`/`lt`/`in`; a `String` column
also offers `contains`/`startsWith`/`endsWith`) and let the schema introspect
cleanly. Class-level memoization of the scalar InputObjects guarantees a
single `IntFilter`/`StringFilter`/etc. type identity across the whole schema,
so two filter instances cannot mint colliding type names.

Expressing `contains`/`startsWith`/`endsWith` as wrapped `LIKE` rather than
inventing DBIO operators keeps the compiler's output inside DBIO's existing,
portable condition vocabulary — it produces conditions any DBIO driver
already understands, instead of pushing substring semantics down as a new
operator every driver would have to implement.

## Consequences

- The filter input shape and the DBIO search condition stay structurally
  parallel by construction; adding an operator means adding one entry to
  `_ops_for` (with an optional `wrap`) and nothing else.
- `contains`/`startsWith`/`endsWith` inherit `LIKE` semantics exactly,
  including the engine's wildcard and case behaviour, and the SQL-wildcard
  characters `%` and `_` inside a user-supplied value are **not** escaped —
  they are interpolated into the `LIKE` pattern as wildcards.
- A column filtered with an operator its scalar does not define raises a
  build- or compile-time error (`_compile_column` dies on an unknown
  operator), rather than silently ignoring it.
- This is the explicit fork divergence point. The acknowledgement that this
  surface departs from MANWAR's design is recorded in the module POD and must
  stay there; future filter changes are changes to *this* re-architecture,
  not a re-port of the upstream filter.
