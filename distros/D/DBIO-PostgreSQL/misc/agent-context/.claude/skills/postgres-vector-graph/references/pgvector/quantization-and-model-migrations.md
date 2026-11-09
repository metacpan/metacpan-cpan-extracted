# Quantization, high dimensions and embedding replacement

## Preserve the two-stage contract

For a 3,072-dimensional full-precision source vector, a candidate index may use a
half-precision cast; keep the original representation for reranking:

```sql
-- Schema sketch: not part of the three-dimensional lab.
CREATE INDEX representation_half_hnsw ON document_embedding
USING hnsw ((embedding::public.halfvec(3072)) public.halfvec_cosine_ops);
```

The candidate query must use the matching cast, dimension and metric. Its final
reranker uses the original full-precision column. Do not assume an index on one
expression accelerates a different expression automatically.

Binary quantization is another candidate-stage option. Quantization and smaller
subvectors trade information for cost; measure candidate recall before reranking.
A reranker cannot recover a relevant document absent from the candidate set.
Reducing dimensions by truncation is valid only when the embedding model supports
that use or the loss has been independently evaluated.

## Never mix embedding spaces during migration

An old vector and a new vector with the same dimension can still be incomparable.
Use a new space/version identifier, a new representation table or a new column.
Do not overwrite the old values in place while queries remain unaware of which
model each row uses.

A staged design:

1. Register the new space and query-embedding implementation.
2. Backfill by immutable source version; reject stale worker output.
3. Build the new index and verify count, norm, coverage and exact/ANN recall.
4. Shadow representative queries and assess relevance, latency and costs.
5. Switch reads with an explicit feature flag; retain a rollback window.
6. Remove the previous representation only after retention/recovery requirements
   are satisfied and the removal is approved.

For text that changes while being embedded, write the result only when its source
version is still current. Failed or pending embeddings need an explicit retrieval
policy, such as lexical fallback, rather than silently serving stale semantics.

Version projection caches and graph-derived features too. A score cached against
model v1 cannot be assumed compatible with v2 just because the document ID did
not change.

## Sources

- [Supabase vector index documentation](https://supabase.com/docs/guides/ai/vector-indexes)
- [Supabase automatic-embedding workflow](https://supabase.com/docs/guides/ai/automatic-embeddings)
- [pgvector upstream reference](https://github.com/pgvector/pgvector)
