-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02 and 04. Read-only. The explicit graph seed is document 101.
-- Graph is an OPTIONAL relevance signal here, never a permission filter.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';
SET LOCAL hnsw.iterative_scan = 'strict_order';
WITH vc AS MATERIALIZED (
    SELECT doc_id, embedding <=> '[1,0,0]'::public.vector(3) AS distance
    FROM skill_lab.document WHERE tenant_id = 1 AND model_id = 'demo-v1'
    ORDER BY embedding <=> '[1,0,0]'::public.vector(3) LIMIT 50
), vr AS (
    SELECT doc_id, row_number() OVER (ORDER BY distance + 0, doc_id) AS rank FROM vc
), lc AS MATERIALIZED (
    SELECT doc_id, ts_rank_cd(fts, websearch_to_tsquery('english','vector search')) AS score
    FROM skill_lab.document
    WHERE tenant_id = 1 AND model_id = 'demo-v1'
      AND fts @@ websearch_to_tsquery('english','vector search')
    ORDER BY score DESC, doc_id LIMIT 50
), lr AS (
    SELECT doc_id, row_number() OVER (ORDER BY score DESC, doc_id) AS rank FROM lc
), raw_graph AS MATERIALIZED (
    SELECT g.doc_id::bigint AS doc_id, g.strength::float8 AS strength
    FROM ag_catalog.cypher('skill_graph', $$
        MATCH (s:document)-[r:related]->(d:document)
        WHERE s.tenant_id = 1 AND s.doc_id = 101
          AND r.tenant_id = 1 AND d.tenant_id = 1
        RETURN d.doc_id, r.strength
    $$) AS g(doc_id ag_catalog.agtype, strength ag_catalog.agtype)
), gc AS MATERIALIZED (
    SELECT d.doc_id, max(g.strength) AS score
    FROM raw_graph g JOIN skill_lab.document d ON d.doc_id = g.doc_id
    WHERE d.tenant_id = 1 AND d.model_id = 'demo-v1'
    GROUP BY d.doc_id ORDER BY score DESC, d.doc_id LIMIT 50
), gr AS (
    SELECT doc_id, row_number() OVER (ORDER BY score DESC, doc_id) AS rank FROM gc
), contributions AS (
    SELECT doc_id, 'vector'::text AS channel, 1.0 / (60 + rank) AS score FROM vr
    UNION ALL SELECT doc_id, 'lexical'::text, 1.0 / (60 + rank) FROM lr
    UNION ALL SELECT doc_id, 'graph'::text, 0.5 / (60 + rank) FROM gr
), fused AS (
    SELECT doc_id, sum(score) AS rrf_score, array_agg(channel ORDER BY channel) AS channels
    FROM contributions GROUP BY doc_id
)
SELECT d.doc_id, d.title, f.rrf_score, f.channels
FROM fused f JOIN skill_lab.document d ON d.tenant_id = 1 AND d.doc_id = f.doc_id
WHERE d.model_id = 'demo-v1'
ORDER BY f.rrf_score DESC, d.doc_id LIMIT 10;
COMMIT;
-- Weights and smoothing are illustrative; strength and RRF are not probabilities.
