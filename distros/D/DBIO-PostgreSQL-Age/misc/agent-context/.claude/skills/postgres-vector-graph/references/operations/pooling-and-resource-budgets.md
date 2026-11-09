# Connection pooling and resource budgets

## Session state and transactions

`LOAD`, `SET`, prepared statements, temporary objects, and transaction-local settings
have different lifetimes. An application connection object is not proof that a
transaction-pooling proxy will retain the same backend across transactions.
Identify the actual pool mode and its supported protocol-prepared-statement
configuration. Do not assume SQL `PREPARE` works through every transaction pool.

Prefer provider-supported AGE preloading/session initialization. Keep each
multi-stage retrieval inside one explicit transaction so its `SET LOCAL`, role,
snapshot, and queries remain together. On a direct session connection, explicit
`LOAD 'age'` can initialize that backend if the role permits it. Running LOAD in a
separate transaction behind a transaction pool may initialize the wrong backend.

The lab and Python example target **direct connections or session pooling**.
Transaction pooling is a separate deployment test, not silently supported by a
successful direct-connection run. Verify both the driver protocol path and AGE
parameter behavior through the production proxy.

## Memory is multiplied by execution shape

Do not set `work_mem` equal to all available RAM. Sort/hash operations and workers
can each consume memory, while concurrent requests, HNSW indexes, PostgreSQL
buffers, kernel cache, maintenance, and the application compete for the same host.
ANN traversal budgets and graph expansion can add substantial work independently.

On modest hardware, start with bounded concurrency and small request budgets.
Increase query, ANN, or build settings one variable at a time, with measured
resident memory, temp I/O, latency, recall, and throughput. A configuration that
wins at concurrency one may cause memory pressure and timeouts under load.

## Practical workload separation

Separate latency-sensitive search from bulk embedding writes, graph ingestion,
index builds, and vacuum/reindex work through schedules, connection pools, or
resource controls. Do not imply every workload needs a second database; first
measure interference and establish admission control.

Keep transactions short. Set statement and lock timeouts appropriate to the
operation; a bulk maintenance timeout should not silently become a request
endpoint's timeout. Bound result size, traversal depth, candidate count, and
batch size in addition to timeouts.

## Benchmark matrix

Include warm/cold cache, representative tenants, selective filters, skewed graph
degree, concurrent writes, connection churn, and overload. Record queue time
separately from database execution. Validate tenant-context reset across connection
reuse, cancellation, exceptions, and transaction rollback. Use database roles
without bypass privileges for isolation tests.

## Sources

- [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html)
- [PostgreSQL 18 SET](https://www.postgresql.org/docs/18/sql-set.html)
- [PostgreSQL 18 resource consumption](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [Psycopg prepared statements](https://www.psycopg.org/psycopg3/docs/advanced/prepare.html)
- [Psycopg transaction management](https://www.psycopg.org/psycopg3/docs/basic/transactions.html)
