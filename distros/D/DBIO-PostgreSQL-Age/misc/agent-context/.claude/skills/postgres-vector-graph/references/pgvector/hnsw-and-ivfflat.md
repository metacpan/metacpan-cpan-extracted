# HNSW and IVFFlat: a controlled tuning procedure

## Select by measured constraints

HNSW maintains a navigation graph over vectors; AGE stores the application's
relationships. They are different structures with different semantics. IVFFlat
partitions vector space into lists and needs representative training data.
Choose between exact search, HNSW and IVFFlat using the eligible data size,
update pattern, build budget, resident memory and target recall.

A useful experiment has three arms: exact filtered scan, HNSW, and IVFFlat where
appropriate. Compare them at matched recall, not only at their default settings.
Include ingestion and vacuum cost, not just a single SELECT latency.

## Knobs and experimental axes

For HNSW, separate construction (`m`, `ef_construction`) from retrieval
(`hnsw.ef_search`) and iterative-scan budgets. For IVFFlat, separate the index's
list count from query probes and iterative max probes. More effort is not free:
record CPU, latency, memory, WAL, build time and recall.

Suggested experiment grid, not default production settings:

| Axis | Example values to test |
|---|---|
| HNSW search effort | 40, 100, 200 |
| Candidate count before reranking | 50, 100, 250 |
| Tenant/filter selectivity | 100%, 10%, 1%, 0.1% |
| Client concurrency | 1, 4, 16; then increase only with headroom |
| Data state | Static, recent inserts, deletes/updates, after maintenance |

Keep all other variables fixed when attributing a difference to one knob. A
request for 10 results and a candidate budget of 10 leaves no allowance for
filters, reranking, per-document deduplication or graph expansion.

## Build and lifecycle

Load representative data before an IVFFlat build. For HNSW, measure resident
memory and the impact of the construction working set. Allocate maintenance
memory from actual headroom, not a tutorial's multi-gigabyte example. With
containers, account for shared-memory limits and parallel workers.

After building, verify `indisvalid`, index definition and actual plans. Recheck
recall after substantial distribution drift or a large update/delete cycle.
Do not automatically schedule frequent rebuilds without a measured reason.
See [deployment](../operations/install-build-deploy.md) and
[benchmarking](../operations/observability-and-benchmarks.md).

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Supabase vector index documentation](https://supabase.com/docs/guides/ai/vector-indexes)
- [PostgreSQL 18 CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html)
- [PostgreSQL 18 resource consumption](https://www.postgresql.org/docs/18/runtime-config-resource.html)
