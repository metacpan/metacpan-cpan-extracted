# Graph-first eligibility, then vector ranking

## Use this when relationships define the search universe

Examples include documents reachable from an approved project, components
reachable through a dependency type, or evidence attached to a selected entity.
First establish a bounded, authorized set of business IDs. Then rank vectors
inside that set. This separates graph eligibility from semantic similarity.

The [worked example](../../examples/sql/05_graph_first_vector.sql) materializes
one-hop graph candidates, joins them to authorized SQL records, and performs
exact cosine-distance ranking over that eligible set. Its result is exact **within
that explicitly defined set**, not a global corpus top-k and not necessarily the
full transitive neighborhood. A one-hop boundary is part of the semantics.

## Three different algorithms

| Algorithm | Correctness statement | Appropriate evidence |
|---|---|---|
| Materialize graph set; exact vector sort | Exact top-k within the complete materialized eligible set | Compare IDs/distances with independent subset ground truth |
| ANN candidates; intersect graph set | Approximate and may underfill or miss the subset's best documents | Measure filtered recall and increase budgets adaptively |
| Relational membership projection + filtered ANN | Approximate; also subject to projection lag | Measure ANN recall and independently audit membership freshness |

Do not describe ANN-plus-intersection as equivalent to exact graph-first search.
Increasing the ANN budget does not prove completeness. An outer `LIMIT` on graph
results can silently redefine eligibility; label it an approximation when used.

## Scale and planning

The complete eligible set may be small enough that exact ranking is faster and
simpler than ANN. Large sets require measurement. Compare graph execution,
ID deduplication, relational join, vector distance calculation, and sorting
separately. Record graph density and high-degree vertices, not just row count.

A materialized intermediate makes the exact-subset semantics explicit and blocks
an accidental global ANN limit. It also costs memory/temp I/O and may lose useful
planner optimizations. Inspect `EXPLAIN (ANALYZE, BUFFERS)` on approved read-only
queries with representative scale; a tiny fixture proves neither speed nor an
HNSW plan.

## Security and parameter boundary

Scope starting vertices, traversed edges, and destination vertices to the tenant.
Join on both tenant and business ID. Do not use a shared business ID alone. Apply
AGE policies and relational policies separately, including base/unlabeled paths.

The lab uses fixed literals for an auditable demonstration. For runtime values,
use AGE's prepared parameter map, not string interpolation. For a two-stage
application implementation, use one short repeatable-read transaction if both
stages need one snapshot; do not assume a row-correlated third argument to
`cypher()` is supported merely because ordinary SQL functions accept expressions.

## Sources

- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
- [Apache AGE prepared statements](https://age.apache.org/age-manual/master/advanced/prepared_statements.html)
- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [PostgreSQL 18 WITH queries](https://www.postgresql.org/docs/18/queries-with.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
