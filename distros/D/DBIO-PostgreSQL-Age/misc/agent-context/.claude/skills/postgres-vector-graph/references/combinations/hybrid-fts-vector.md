# Hybrid full-text and vector retrieval

## Pipeline

Run two bounded, authorized candidate queries. Lexical retrieval uses a suitable
text-search configuration, a matching `tsvector`, and a GIN index. Semantic
retrieval uses one embedding space and the matching distance operator. Fuse
**ranks**, not raw lexical scores and cosine distances with unrelated scales.

The worked [SQL example](../../examples/sql/03_hybrid_fts_vector.sql) uses
reciprocal rank fusion:

```text
RRF(document) = sum over channels c of weight[c] / (smoothing + rank[c, document])
```

A document absent from a channel contributes zero. Deduplicate inside each
channel before ranking; each document contributes at most once per channel.
`smoothing = 60` and equal weights in the lab are illustrative choices, not
universally optimal settings. RRF is not a probability or calibrated relevance
score. Fit settings on development queries, then report held-out results.

## Preserve useful access paths

The ANN candidate query orders by the raw distance expression and limits its
candidate count. Rank and deterministic tie-breaking are applied *outside* that
candidate boundary. A transformed similarity expression or secondary sort key
inside the ANN query can change the chosen plan. Inspect the actual plan.

The lexical channel filters with `@@` before ranking. PostgreSQL's `ts_rank` and
`ts_rank_cd` are native ranking functions, **not BM25**. For true BM25, select a
separate implementation and verify its exact PostgreSQL 18 compatibility and
semantics; this skill does not silently install another extension.

## Failure modes and controls

A common filter must not be applied only after fusion: unauthorized or deleted
records then consume the candidate budget, and intermediate results may leak.
A common `LIMIT 20` is not evidence that both channels can find enough eligible
records. Record underfill by channel and tenant/filter selectivity.

An empty lexical result can legitimately reduce the run to semantic ranking.
An embedding failure can reduce it to lexical ranking if the product permits
that fallback. Report which channels actually ran; do not replace missing vectors
with zero vectors. A required permission graph is never an optional channel.

For multilingual content, model text-search language separately from embedding
space. For document aggregation, deduplicate chunk hits deliberately and retain
source offsets. Add a reranker only after measuring the baseline; reranking cannot
recover relevant items absent from all candidate sets.

## Evaluation

Report candidate recall against exact vector search separately from relevance
metrics such as nDCG and judged task success. Also report latency, candidate counts,
channel overlap, duplicate rate, and empty/underfilled queries. Include rare exact
terms, identifiers, paraphrases, multilingual queries, and selective filters.

## Sources

- [PostgreSQL 18 text-search controls](https://www.postgresql.org/docs/18/textsearch-controls.html)
- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [PostgreSQL 18 EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html)
