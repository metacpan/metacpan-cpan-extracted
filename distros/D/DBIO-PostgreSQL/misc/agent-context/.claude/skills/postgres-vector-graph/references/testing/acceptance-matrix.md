# Acceptance matrix and evidence levels

## Evidence vocabulary

**Source-reviewed** means a primary source was inspected. **Static-checked** means
local file structure or Python syntax was validated. **Unit-tested** means the
specified offline function was executed. **Integration-tested** requires a live,
identified database/driver/pool. **Benchmarked** requires measured workload results.
Never promote one level to another.

## Required acceptance checks

| Area | Check | Pass evidence |
|---|---|---|
| Compatibility | Exact PG major, extension binary/SQL versions, schemas, provider support | Fingerprint plus successful target initialization |
| Scalar boundary | Integer, string, NULL, JSONB conversion and prepared maps | Queries under deployed AGE/driver/pool versions |
| SQL + graph atomicity | Roll back a write in both layers | No record/vertex survives; repeat with induced failure |
| Replay/concurrency | Duplicate event, two writers, stale event, delete race | Unique stable identities and no resurrection |
| ANN | Compare same-space, same-filter/snapshot exact ground truth | Recall distribution and underfill counts |
| Rank fusion | Duplicates, weights, empty channels, deterministic order | Offline unit tests plus real-query relevance evaluation |
| Graph semantics | Direction/type/depth, cycles, hub truncation, missing endpoints | Known-fixture expected IDs and provenance |
| Tenant isolation | SQL/FTS/vector/graph/direct-label access and joins | Zero cross-tenant results as restricted non-owner roles |
| Pool isolation | Tenant changes, cancellation, errors, backend reassignment | No leaked context; preparation and AGE initialization work |
| Recovery | Clean restore and extension upgrade rehearsal | Structural, role, known-query and replay checks pass |
| Load | Representative selectivity, graph density, concurrency and writes | Resource/latency/recall results under stated conditions |

## Included tests and their limits

The SQL lab supplies deterministic synthetic fixtures, a cross-model rollback
check, and selected RLS assertions. It is opt-in and requires an approved disposable
PG18 database. Role setup changes cluster-level role state and is a separate
approval gate. The example does not cover all attack/query shapes or production
policies. Use the detailed [AGE security plan](../age/security-and-rls.md).

Offline Python tests validate fusion/metric arithmetic, input rejection, local
links, manifests, and file syntax. They do not parse PostgreSQL/Cypher semantics,
connect to a database, prove index use, or measure retrieval quality. The agent
scenario file is an evaluation specification, not a record of model evaluation.

Failed psql assertions raise an SQL exception under `ON_ERROR_STOP`; the scripts
do not assume that `\quit 1` supplies a portable failure exit code.

Read [VALIDATION.md](../../VALIDATION.md) for the actual results from package
creation. Add deployment-specific test results instead of overwriting limitations
with an unqualified “tested” badge.

## Adversarial requests

A review must reject an embedding-dimension-only model migration, HNSW graph/domain
graph equivalence, string-interpolated Cypher, automatic tenant RLS propagation,
strict-order/exact-recall equivalence, arbitrary user-set tenant GUC as
authentication, unbounded traversal, and fabricated compatibility for later PG
majors. See [agent scenarios](../../tests/scenarios.json) for expected routing and
response requirements.

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Apache AGE prepared statements](https://age.apache.org/age-manual/master/advanced/prepared_statements.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [Psycopg transaction management](https://www.psycopg.org/psycopg3/docs/basic/transactions.html)
- [PostgreSQL 18 SQL dump](https://www.postgresql.org/docs/18/backup-dump.html)

- [PostgreSQL 18 psql scripting and exit status](https://www.postgresql.org/docs/18/app-psql.html)
