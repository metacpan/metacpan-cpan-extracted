# Troubleshooting by symptom and evidence

| Symptom | First checks | Avoid |
|---|---|---|
| `age`/`vector` is unavailable | Server major, installed control/shared libraries, provider allowlist | Assuming CREATE EXTENSION downloads it |
| Undefined `cypher`, `agtype`, or operator | Correct extension schema, trusted search path, AGE backend initialization | Granting superuser to the application |
| AGE works directly but fails through pool | Pool mode, backend initialization, protocol preparation, transaction boundaries | Assuming session settings survived backend reassignment |
| Fewer than k ANN results | Eligible corpus size, model filter, zero/NULL vectors, iterative scan limits, index predicate | Claiming strict ordering means exact recall |
| HNSW not chosen | Raw ORDER BY distance + LIMIT, operator class, matching cast, table size, actual plan | Forcing the index without a cost/recall comparison |
| High-dimension vector index fails | Index-type dimension limit versus storage limit | Treating stored vector capacity as ANN capacity |
| Generated expression fails on PG18 | VIRTUAL default and extension function/type restrictions; use STORED when appropriate | Copying old DDL without checking generated-column semantics |
| agtype string includes quotes | Verified scalar/JSONB casts for the installed AGE release | Removing quotes with ad hoc string slicing |
| Cypher parameter fails | Prepared SQL, third agtype map, literal Cypher text, driver/pool support | Putting `%s` or SQL `$1` inside the Cypher text |
| MERGE duplicates under concurrent load | Stable key registry, concurrent transactions, writer serialization/retry | Calling replay-friendly MERGE a uniqueness constraint |
| Tenant leak only in graph results | Policies/grants on labels, edges, base tables, unrestricted paths, role bypass | Assuming SQL table RLS automatically propagated |
| SQL and graph disagree after failure | Same connection/transaction, outbox version ordering, retries, deletion tombstones | Blind full graph rebuild on production |
| Search slows after ingestion | Table/index growth, bloat/vacuum, statistics, build/write contention | A universal work_mem or ef_search value |
| Restore completes but queries fail | Extension binaries/versions, restore errors, schemas, policies, graph IDs/mappings | Treating exit success or row counts as complete recovery proof |

## Diagnostic response format

State the observed failure, expected behavior, exact versions and role, smallest
reproducer, hypothesis, read-only observation, proposed change, and acceptance
check. Distinguish confirmed cause from a plausible hypothesis. Do not make several
unmeasured configuration changes and attribute improvement to one of them.

## Safe escalation

Ask for sanitized plans and the environment fingerprint rather than credentials
or production content. Execute approved bounded reads first. Before an index build,
policy change, extension update, or data repair, state the target, lock/load impact,
rollback path, and test. Do not delete an index solely because its name resembles
a duplicate; inspect its definition, validity, dependencies, and workload usage.

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Apache AGE setup](https://age.apache.org/age-manual/master/intro/setup.html)
- [Apache AGE prepared statements](https://age.apache.org/age-manual/master/advanced/prepared_statements.html)
- [PostgreSQL 18 generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html)
