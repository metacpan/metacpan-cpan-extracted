# Three-way retrieval without conflating ranking and authorization

## Independent signals, explicit semantics

The [three-way SQL example](../../examples/sql/06_three_way_fusion.sql) combines
lexical relevance, semantic proximity, and a one-hop graph relationship signal.
Each channel contributes a bounded, deduplicated ranked list. Weighted RRF combines
those lists while preserving the contributing channels for explanation.

The graph channel ranks a fixture's explicit `strength` property. That number is
a demonstration ranking feature, not a calibrated probability or a guarantee that
an assertion is true. The source entity is explicitly supplied as part of the
request; the example does not pretend to perform entity linking from query text.

## Hard filters versus relevance channels

A permission graph is a hard constraint on **all** candidate channels. It cannot
be represented as one optional contribution to RRF: a document excluded by the
permission graph might still win through the lexical/vector channels. Construct
authorized eligibility first, then rank inside it.

Likewise, a required product/version relation should be a filter when the user
requests that exact scope. A graph channel is appropriate when relationships are
useful supporting relevance, not when they define admissibility.

## Deduplication and evidence

Collapse multiple graph paths to a single document contribution before assigning
ranks. Choose a documented aggregation such as maximum supported edge score,
minimum hop count, or a validated learned score. Do not count every path as a vote.
Shared provenance and repeated extraction are correlated evidence.

Return business IDs and component ranks. Keep source evidence IDs and extractor
versions available for audit. Avoid describing an RRF score as confidence. A
weakest-edge path score is a heuristic unless its probabilistic assumptions have
been demonstrated on the actual data.

## Evaluation sequence

Start with FTS-only and vector-only baselines. Compare two-way fusion, then add
the graph channel with the same final result budget and latency accounting.
Measure whether the graph adds relevant candidates that the other channels miss,
not just whether scores or result counts increase. Include graph corruption,
stale/deleted relationships, disconnected queries, and high-degree hubs.

Tune channel weights, smoothing, and candidate budgets on development queries.
Report held-out results with empty-channel behavior and per-tenant/filter slices.
Use the offline [metrics implementation](../../scripts/retrieval_metrics.py) to
check rank-fusion arithmetic; those unit tests do not evaluate real retrieval
quality, graph correctness, or database execution.

## Sources

- [PostgreSQL 18 text-search controls](https://www.postgresql.org/docs/18/textsearch-controls.html)
- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
- [Apache AGE upstream repository](https://github.com/apache/age)
