# Query plans and index boundaries

## Read the plan before prescribing a setting

Capture `EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON)` on an approved read
query and representative data. `ANALYZE` executes the statement. Do not use it on
unapproved writes; rollback cannot undo every possible external effect.

Compare estimated/actual rows, loops, filter rejection, sort spills, heap access,
index names, join order and total execution time. Check plans for the actual
application role and tenant distribution, not only for a privileged administrator.
Use repeatable inputs and record warm/cold cache conditions.

## Preserve an ANN-compatible inner query

```sql
SELECT doc_id, embedding <=> $1::public.vector(3) AS distance
FROM skill_lab.document
WHERE tenant_id = $2 AND model_id = 'demo-v1'
ORDER BY embedding <=> $1::public.vector(3)
LIMIT $3;
```

These placeholders are a driver/prepared SQL template, not raw psql substitution.
Do not wrap the inner ordering in `1 - distance DESC`, `abs(...)`, a weighting
formula, or an unrelated tie-breaker and assume the same ANN plan remains.
Compute presentation similarity and stable tie-breaking in an outer stage.

## Composition is not automatic index fusion

A B-tree on tenant metadata and an HNSW index do not promise a joint bitmap plan.
A GIN FTS index does not promise ordered top-k by `ts_rank_cd`. A Cypher CTE and a
vector ORDER BY do not promise traversal/filter pushdown. Inspect all boundaries.

A materialized CTE can deliberately establish a small eligible set for exact
ranking, or establish the candidate set before reranking. That fence can also
prevent useful optimization. Use it to express an intended boundary, not as a
universal “make it faster” annotation.

## Maintenance-aware index design

Every extra index adds write, storage, vacuum and recovery work. Build only
indexes attached to a tested access path. Keep a migration plan for concurrent
build failures and invalid indexes. `IF NOT EXISTS` only compares the name; audit
`pg_get_indexdef()` instead of treating a matching name as a matching definition.

After data distribution changes, run the appropriate statistics maintenance and
compare new plans. A sequential scan on eight synthetic rows is sensible and is
not evidence that the production index is broken.

## Output aliases and sorting

An output alias can stand alone in `ORDER BY`, but cannot be used inside another
expression at the same SELECT level. `SELECT expr AS distance ... ORDER BY distance`
is valid; to use `distance + 0`, make distance an input column through a subquery
or CTE first. The relaxed-ANN examples apply `+ 0` only in that outer scope.

## Sources

- [PostgreSQL 18 EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html)
- [PostgreSQL 18 WITH queries](https://www.postgresql.org/docs/18/queries-with.html)
- [PostgreSQL 18 CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html)
- [PostgreSQL 18 multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html)

- [PostgreSQL 18 ORDER BY rules](https://www.postgresql.org/docs/18/queries-order.html)
