-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02. Read-only. Shows distinct exact and approximate retrieval shapes.
BEGIN READ ONLY;
SET LOCAL search_path = pg_catalog, ag_catalog, public;
SET LOCAL statement_timeout='10s';
-- Exact baseline over a materialized eligible subset (no approximate inner LIMIT).
WITH eligible AS MATERIALIZED (
    SELECT doc_id,embedding FROM skill_lab.document
    WHERE tenant_id=1 AND model_id='demo-v1'
)
SELECT doc_id,embedding <=> '[1,0,0]'::public.vector(3) AS distance
FROM eligible ORDER BY distance,doc_id LIMIT 3;

-- ANN-capable query; tiny fixtures may still use a sequential plan.
SET LOCAL hnsw.iterative_scan='strict_order';
SET LOCAL hnsw.ef_search=100;
SELECT doc_id,embedding <=> '[1,0,0]'::public.vector(3) AS distance
FROM skill_lab.document WHERE tenant_id=1 AND model_id='demo-v1'
ORDER BY embedding <=> '[1,0,0]'::public.vector(3) LIMIT 3;

-- Relaxed scan requires an explicit final sort; +0 is relevant on PG17 and later.
SET LOCAL hnsw.iterative_scan='relaxed_order';
WITH candidates AS MATERIALIZED (
    SELECT doc_id,embedding <=> '[1,0,0]'::public.vector(3) AS distance
    FROM skill_lab.document WHERE tenant_id=1 AND model_id='demo-v1'
    ORDER BY embedding <=> '[1,0,0]'::public.vector(3) LIMIT 20
)
SELECT * FROM candidates ORDER BY distance + 0,doc_id LIMIT 3;
COMMIT;
-- Strict ordering is not exact recall. ef_search=100 is illustrative, not a preset.
