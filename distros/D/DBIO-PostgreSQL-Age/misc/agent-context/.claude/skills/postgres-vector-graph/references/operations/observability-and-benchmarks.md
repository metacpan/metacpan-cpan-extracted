# Observe correctness, relevance, and performance separately

## Capture the environment

Use the [fingerprint template](../../templates/environment-fingerprint.json).
Record server and extensions, role/pool, hardware, dataset size, vector dimension
and space, metric/index parameters, graph degree distribution, query/filter slices,
concurrency, timeout settings, and cache condition. Include query plans and exact
configuration hashes with benchmark artifacts.

## Five different measurements

| Property | Measurement | What it does not establish |
|---|---|---|
| ANN fidelity | Recall@k versus exact search over the same eligible snapshot | Human relevance |
| Retrieval relevance | Judged nDCG/MRR/task metrics with held-out queries | Tenant isolation |
| Performance | p50/p95/p99 latency, throughput, queue time, memory/temp I/O | Correctness under failure |
| Security | Negative tests with real restricted roles across every channel | Absence of all side channels |
| Consistency | Version lag, orphan/duplicate audit, rollback/replay tests | Recoverability from a lost system |

Never compare ANN with a ground-truth query using a different tenant filter,
embedding model, distance metric, deleted-record rule, or snapshot. For exact
vector ground truth, confirm the plan really calculates distances across all
eligible records rather than reusing an approximate index. A materialized eligible
set followed by a distance sort is a useful clear baseline.

## Instrument stages

Measure lexical retrieval, vector search, graph traversal, ID joins, reranking,
and serialization separately. Record candidate counts and channel overlap as
well as timing. Underfill is a diagnostic signal even when the query is fast.
Use PostgreSQL activity/statistics views and approved query-level instrumentation;
`pg_stat_statements` is optional and requires its own availability/configuration
gate. Avoid logging raw embeddings, customer text, credentials, or unrestricted
Cypher property maps.

`EXPLAIN ANALYZE` executes its statement. Limit it to approved read-only workloads
unless write-side effects are deliberately contained and authorized. Buffer and
I/O observations should be interpreted with cache and concurrency context.

## Experimental discipline

Change one budget or index parameter at a time; preserve the baseline. Include
rare identifiers, paraphrases, empty results, multilingual content, dense hubs,
selective tenants, and cancellation. Run enough queries and repetitions to reveal
variance; do not turn one favorable latency into a service-level claim.

The offline [metrics script](../../scripts/retrieval_metrics.py) checks deterministic
rank arithmetic and input validation. It has no database connection and cannot
produce a real recall/latency result without supplied rankings. The CSV template
contains headers only, never fabricated measurements.

## Sources

- [PostgreSQL 18 cumulative statistics](https://www.postgresql.org/docs/18/monitoring-stats.html)
- [PostgreSQL 18 EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html)
- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [PostgreSQL 18 resource consumption](https://www.postgresql.org/docs/18/runtime-config-resource.html)
