# ADR 0006 — pgvector query DSL and types

- Status: accepted
- Date: 2026-08-15
- Tags: pgvector, dsl, expand-op, inflate, opclass, resultset

## Context

pgvector adds vector types (`vector`, `halfvec`, `sparsevec`) and a family of
distance operators (`<->`, `<=>`, `<#>`, `<+>`, `<~>`, `<%>`) to PostgreSQL.
The operators are the engine's only query surface for similarity search, but
they differ structurally from the JSONB operators ADR 0005 registered through
`expand_op`: a distance operator returns a *value* (the distance), not a
boolean predicate. `WHERE embedding <-> ? < 5` is two operators, not one —
`<->` produces the distance, `<` compares it. Registering `<->` as a WHERE
predicate (the `%JSONB_OP` pattern) would be wrong: there is no boolean to
evaluate, and the operator is equally at home in `ORDER BY` and `SELECT`,
where `expand_op` predicates never appear.

The types also need value conversion — PostgreSQL's text I/O format is
`[0.1,0.2]` / `{i:v,...}/N`, not Perl structures — and the ANN index access
methods (`hnsw`, `ivfflat`) have no default operator class, so an index on a
vector column must name one or `CREATE INDEX` is rejected.

## Decision

Ship a public `vector()` DSL as the primary query surface, keep the distance
operators out of `expand_op`, default pgvector columns to inflate/deflate, and
document the opclass pairing as a declaration-time concern.

- **DSL over transparent operators.** `DBIO::PostgreSQL::Vector` exports a
  `vector()` helper (`Vector.pm`) returning an operator object
  (`DBIO::PostgreSQL::Vector::Op`). A distance method (`l2_distance`,
  `cosine_distance`, `max_inner_product`, `l1_distance`, `hamming_distance`,
  `jaccard_distance`) selects the operator and query vector and renders
  `(col <op> ?::cast)` with the vector as a bind (`Vector/Op.pm`, `_distance`);
  a consumption method (`as_order`, `as_select`, `lt`/`le`/`gt`/`ge`) turns
  that into a SQL::Abstract fragment. The operators are B<not> registered on
  the SQLMaker — `search({ 'me.embedding' => { '<->' => ... } })` is not a
  thing. The DSL is the surface.
- **Cast strategy.** The placeholder cast defaults to `vector` (`?::vector`); a
  sparsevec query vector (hashref) defaults to `sparsevec` instead; an explicit
  `cast` option on `vector()` overrides either (`Vector/Op.pm`, `_distance`).
  That override is the escape hatch for `halfvec`/`sparsevec`/
  `bit` columns, and `nearest_neighbors` passes it through (`ResultSet.pm`,
  `nearest_neighbors`). A sparsevec hashref carries its own dimensions
  (`{ dims => N, values => {...} }`); on the value side the dimensions come
  from the column declaration `sparsevec(N)`.
- **inflate/deflate by default.** `DBIO::PostgreSQL::InflateColumn::Vector` is
  loaded by `DBIO::PostgreSQL::Result` (`Result.pm`, `load_components`), so
  declaring a pgvector column is the whole opt-in — the same shape as the
  `resultset_class` promotion. An ArrayRef deflates to `[0.1,0.2]` and inflates
  back; a sparsevec HashRef deflates to `{i:v,...}/N` and inflates to
  `{ dims => N, values => {...} }`. The conversion is idempotent: a plain
  string passes through verbatim in both directions, so an already-serialized
  value is never double-serialized. Opt out per column with
  `inflate_pgvector => 0`. `bit` columns are B<not> inflated — bitstrings are
  already the natural Perl representation and feed the Hamming/Jaccard
  operators directly.
- **Opclass representation.** The distance keyword set on `nearest_neighbors`
  maps to the operator methods (`ResultSet.pm`, `%DISTANCE_METHOD`), and the
  operator class is declared where it belongs, in `opclasses` on `pg_index`
  (`Result.pm`, `pg_index`). An `hnsw`/`ivfflat` index only answers for the
  operator its operator class was built for; ordering by an operator no index
  covers is not an error — PostgreSQL falls back to a sequential scan.
  `EXPLAIN` is the only real confirmation.
- **nearest_neighbors placement.** The KNN sugar lives on its own
  `DBIO::PostgreSQL::ResultSet` class, promoted via `resultset_class` when a
  pgvector column is registered (`Result.pm`, `register_column`) — not by
  manipulating `@ISA`. A custom resultset that already inherits from it is left
  alone.

## Rationale

The distance operators are values, not predicates, so the `expand_op` path ADR
0005 used for JSONB does not fit: `expand_op` handlers render a boolean
expression for `WHERE`, and the same operator must also appear in `ORDER BY`
and `SELECT`. A DSL object that renders `(col <op> ?::cast)` and then lets the
caller consume it as an order term, a select term, or a threshold comparison
covers all three positions with one construction. The cast is a placeholder
cast because the query vector is a bind — inlining it would forfeit prepared
statements and invite injection; the default `vector` cast covers the common
case and the `cast` option covers the rest. inflate/deflate defaults to the
column declaration as the opt-in because that is the moment the driver knows
the type; making it opt-in-by-default matches how `resultset_class` promotion
already works and keeps a plain string round-trip lossless. The opclass
pairing is a declaration-time concern because nothing at query time knows
which indexes the database actually has — the driver cannot check it, so the
documentation makes the pairing explicit and points at `EXPLAIN`.

## Consequences

- Similarity queries require `use DBIO::PostgreSQL::Vector qw(vector)` — a
  deliberate, explicit dependency, mirroring the `jsonb()` DSL. The distance
  operators are never available as transparent `search()` keys.
- The query vector always travels as a bind placeholder cast to the column's
  type; generated SQL reads `(me.embedding <=> ?::vector)`, never an inlined
  literal.
- pgvector columns inflate/deflate by default once `PostgreSQL::Result` is
  loaded; `inflate_pgvector => 0` opts a single column out. `bit` columns are
  untouched.
- An `hnsw`/`ivfflat` index without an `opclasses` entry is rejected by
  PostgreSQL at `CREATE INDEX` time — the `pg_index` POD documents the rule
  and the required operator classes.
- `nearest_neighbors` is sugar over the DSL, not a replacement: it always
  orders ascending and selects `neighbor_distance`; anything else uses
  `vector()` directly.

## Addendum 2026-10-04 (karr k85)

One premise in the Context is wrong for `ivfflat`, and one Consequence follows
it. The Context says both ANN access methods have no default operator class;
the Consequences say an `hnsw`/`ivfflat` index without an `opclasses` entry is
rejected at `CREATE INDEX` time. Both hold for `hnsw` only. pgvector declares
`vector_l2_ops` as `DEFAULT FOR TYPE vector USING ivfflat`
(`pg_opclass.opcdefault`), so an `ivfflat` index on a `vector` column that
names no operator class is accepted and built with `vector_l2_ops` (found in
karr k81, pinned live by `t/48-index-opclass-live.t`).

The decision stands as written: the operator class is declared in `opclasses`
on `pg_index`, and the pairing with the query's distance stays a
declaration-time concern. What changes is what the declaration does on
`ivfflat`:

- On `hnsw` an `opclasses` entry is required, as the ADR says.
- On `ivfflat` it selects the distance. Without one the index serves `<->`;
  `vector_cosine_ops` or `vector_ip_ops` has to be named to get another.
- `pg_get_indexdef` prints an operator class only when it is not the default,
  so an `ivfflat` index declared with `vector_l2_ops` is introspected without
  one — `column_opclasses` in `DBIO::PostgreSQL::Introspect::Parse` reports
  none and `result_class_extra_statements` in `DBIO::PostgreSQL::Introspect`
  regenerates the `pg_index` without `opclasses`. Nothing is lost: a redeploy
  without it gets the same default back.

The original text above is left as written; the POD and the code comments that
repeated the premise were corrected with this addendum.
