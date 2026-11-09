-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02. Read-only. Output: one contribution per document per channel.
-- Fixed literals are demonstration request values, not interpolation guidance.
BEGIN READ ONLY;
SET LOCAL search_path = pg_catalog, ag_catalog, public;
SET LOCAL statement_timeout = '10s';
SET LOCAL hnsw.iterative_scan = 'strict_order';
WITH vector_candidates AS MATERIALIZED (
    SELECT doc_id, embedding <=> '[1,0,0]'::public.vector(3) AS distance
    FROM skill_lab.document
    WHERE tenant_id = 1 AND model_id = 'demo-v1'
    ORDER BY embedding <=> '[1,0,0]'::public.vector(3)
    LIMIT 50
), vector_ranks AS (
    SELECT doc_id, row_number() OVER (ORDER BY distance + 0, doc_id) AS rank
    FROM vector_candidates
), lexical_candidates AS MATERIALIZED (
    SELECT doc_id, ts_rank_cd(fts, websearch_to_tsquery('english', 'vector search')) AS score
    FROM skill_lab.document
    WHERE tenant_id = 1 AND model_id = 'demo-v1'
      AND fts @@ websearch_to_tsquery('english', 'vector search')
    ORDER BY score DESC, doc_id LIMIT 50
), lexical_ranks AS (
    SELECT doc_id, row_number() OVER (ORDER BY score DESC, doc_id) AS rank
    FROM lexical_candidates
), contributions AS (
    SELECT doc_id, 'vector'::text AS channel, 1.0 / (60 + rank) AS score FROM vector_ranks
    UNION ALL
    SELECT doc_id, 'lexical'::text, 1.0 / (60 + rank) FROM lexical_ranks
), fused AS (
    SELECT doc_id, sum(score) AS rrf_score,
           array_agg(channel ORDER BY channel) AS channels
    FROM contributions GROUP BY doc_id
)
SELECT d.doc_id, d.title, f.rrf_score, f.channels
FROM fused f JOIN skill_lab.document d ON d.tenant_id = 1 AND d.doc_id = f.doc_id
WHERE d.model_id = 'demo-v1'
ORDER BY f.rrf_score DESC, d.doc_id LIMIT 10;
COMMIT;
