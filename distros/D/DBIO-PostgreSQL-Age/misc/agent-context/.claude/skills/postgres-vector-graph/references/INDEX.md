# Reference index

Load only the references needed for the task. Start with [SKILL.md](../SKILL.md).
The examples use one shared lab so their identities and assumptions remain consistent.

## Compatibility

- [Compatibility is a gate, not a slogan](compatibility/version-matrix.md)

## PostgreSQL 18

- [Native full-text search without false BM25 claims](postgres/full-text-search.md)
- [PostgreSQL 18 baseline: what changes the design](postgres/pg18-baseline.md)
- [Query plans and index boundaries](postgres/planner-and-indexes.md)
- [Schema and integrity across three models](postgres/schema-and-integrity.md)
- [Relational authorization and RLS](postgres/security-and-rls.md)
- [Transactions, snapshots, locking and retries](postgres/transactions-and-locking.md)

## pgvector

- [Filtered ANN: candidate starvation and exact alternatives](pgvector/filtered-ann.md)
- [HNSW and IVFFlat: a controlled tuning procedure](pgvector/hnsw-and-ivfflat.md)
- [Quantization, high dimensions and embedding replacement](pgvector/quantization-and-model-migrations.md)
- [Vector types, metrics and index limits](pgvector/types-and-metrics.md)

## Apache AGE

- [AGE advanced capabilities: version-gated exploration](age/advanced-capabilities.md)
- [Graph modeling, indexes and ingestion](age/modeling-indexes-and-ingestion.md)
- [AGE security and tenant isolation](age/security-and-rls.md)
- [AGE setup and the SQL/Cypher boundary](age/setup-and-cypher.md)
- [agtype, JSONB, parameters and drivers](age/types-parameters-and-drivers.md)

## Combinations

- [Choose a composition and make ownership explicit](combinations/architecture-and-identities.md)
- [Atomic cross-model writes and asynchronous projections](combinations/consistency-and-outbox.md)
- [Graph-first eligibility, then vector ranking](combinations/graph-first-vector.md)
- [Hybrid full-text and vector retrieval](combinations/hybrid-fts-vector.md)
- [Three-way retrieval without conflating ranking and authorization](combinations/three-way-fusion.md)
- [Vector seeds followed by bounded graph expansion](combinations/vector-first-graph.md)

## Operations

- [Backup, recovery, replication, and upgrades](operations/backup-recovery-upgrades.md)
- [Installation and deployment gates](operations/install-build-deploy.md)
- [Observe correctness, relevance, and performance separately](operations/observability-and-benchmarks.md)
- [Connection pooling and resource budgets](operations/pooling-and-resource-budgets.md)
- [Troubleshooting by symptom and evidence](operations/troubleshooting.md)

## Integrations

- [Reviewed companion skills and dependency policy](integrations/companion-skills.md)

## Testing

- [Acceptance matrix and evidence levels](testing/acceptance-matrix.md)

## Worked examples and tools

See the [lab walkthrough](../README.md#optional-live-sql-lab), [Python vector-first example](../examples/python/vector_first_graph.py), [offline metrics](../scripts/retrieval_metrics.py), and [validation status](../VALIDATION.md).
