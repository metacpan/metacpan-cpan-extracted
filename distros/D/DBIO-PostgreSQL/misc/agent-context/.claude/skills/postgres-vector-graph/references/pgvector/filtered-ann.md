# Filtered ANN: candidate starvation and exact alternatives

## Diagnose the symptom precisely

Fewer than k rows can mean fewer than k eligible documents, NULL/zero cosine
vectors, model mismatch, candidate starvation, post-retrieval permission filters,
or exhausted search limits. First count the eligible set and compare with exact
filtered search. Do not immediately increase every global memory setting.

Approximate candidate retrieval may encounter many rows that fail the filter.
Iterative scans can continue searching, but remain bounded. HNSW `strict_order`
means distance ordering of the returned candidates, not exhaustive exact recall.
IVFFlat's iterative mode is `relaxed_order`; do not invent a strict mode for it.

## Decision sequence

**Small eligible set:** filter through relational indexes, materialize the eligible
rows when the plan requires that boundary, then compute exact vector distances.
This can be both simpler and more accurate than forcing ANN.

**Large eligible set:** keep authorization/model predicates in the ANN query,
then tune search effort and iteration limits against exact ground truth.

**Stable high-volume segments:** assess partial indexes or partitioning. Do not
create one partition/index per arbitrary tenant without accounting for catalog,
planning, maintenance and operational scale.

## Relaxed ordering needs an outer sort

```sql
BEGIN;
SET LOCAL hnsw.iterative_scan = 'relaxed_order';
WITH candidates AS MATERIALIZED (
  SELECT doc_id, embedding <=> '[1,0,0]'::public.vector(3) AS distance
  FROM skill_lab.document
  WHERE tenant_id = 1 AND model_id = 'demo-v1'
  ORDER BY embedding <=> '[1,0,0]'::public.vector(3)
  LIMIT 50
)
SELECT * FROM candidates ORDER BY distance + 0, doc_id LIMIT 10;
COMMIT;
```

The outer `+ 0` follows the upstream PG17+ ordering guidance. Preserve the raw
distance expression in the inner ANN query. A distance threshold outside a
bounded candidate CTE only filters those candidates; it does not enumerate every
row in the database within that radius.

## Security is not recall

RLS may prevent unauthorized output while a shared ANN index still allows one
tenant's vectors to influence another tenant's recall or latency. Treat workload
interference, timing sensitivity and result confidentiality as separate concerns.
Partitioning is an isolation design input, not a replacement for privileges.

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [PostgreSQL 18 WITH queries](https://www.postgresql.org/docs/18/queries-with.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
