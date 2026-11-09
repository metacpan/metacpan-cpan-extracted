# PostgreSQL 18 baseline: what changes the design

## Features to exploit deliberately

PostgreSQL 18 introduces asynchronous I/O for selected operations, B-tree skip
scan, virtual generated columns, and `uuidv7()`. These are not a blanket speedup
for every extension, every query, or every storage device. The release also
contains planner and observability changes; compare plans after upgrading.

For this skill, three consequences matter immediately:

**Generated columns must be explicit.** PG18 defaults a generated column to
`VIRTUAL`. Use `STORED` for the materialized FTS document in the lab. A virtual
generation expression cannot reference user-defined types/functions, including
through operators or casts. An expression involving `vector`, `halfvec` or
`agtype` is therefore not a generic virtual-column recipe. External embedding
API calls belong in an ingestion worker, not an allegedly immutable function.

**Skip scan is a planner opportunity, not a schema replacement.** A composite
B-tree can sometimes serve a condition without an equality on its leading key.
Still design the tenant/filter access path from measured cardinalities. A skip
scan is unrelated to HNSW iterative scanning and does not turn HNSW into a
multicolumn B-tree.

**AIO requires workload evidence.** Identify the active I/O method, storage
latency, cache state and query shape. Do not promise a percentage improvement
for graph traversal or ANN by extrapolating a sequential-scan benchmark.

## Useful schema pattern

```sql
CREATE TABLE app_event (
    event_id uuid PRIMARY KEY DEFAULT uuidv7(),
    tenant_id bigint NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    payload jsonb NOT NULL
);
```

This is a standalone illustration, not part of the lab schema. UUID ordering is
not access control, and IDs with time information are not secrets. Choose keys
from replication, external-reference and storage requirements, not novelty.

## Review questions

Does the migration rely on the previous generated-column default? Are index
expressions and operator classes unchanged? Did statistics survive or get rebuilt
as intended? Have production plans, application-role privileges and extension
upgrade procedures been rehearsed? Has every new capability been verified against
`/docs/18/` rather than whichever major `/docs/current/` happens to reference?

## Sources

- [PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html)
- [PostgreSQL 18 generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
- [PostgreSQL 18 multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html)
- [PostgreSQL 18 resource consumption](https://www.postgresql.org/docs/18/runtime-config-resource.html)
