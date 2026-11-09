-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02 and 04. Read-only: exact ranking INSIDE the complete one-hop subset.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';
WITH graph_ids AS MATERIALIZED (
    SELECT DISTINCT g.doc_id::bigint AS doc_id
    FROM ag_catalog.cypher('skill_graph', $$
        MATCH (s:document)-[r:related]->(d:document)
        WHERE s.tenant_id = 1 AND s.doc_id = 101
          AND r.tenant_id = 1 AND d.tenant_id = 1
        RETURN d.doc_id
    $$) AS g(doc_id ag_catalog.agtype)
), eligible AS MATERIALIZED (
    SELECT d.doc_id, d.title, d.embedding
    FROM skill_lab.document d JOIN graph_ids g ON g.doc_id = d.doc_id
    WHERE d.tenant_id = 1 AND d.model_id = 'demo-v1'
)
SELECT doc_id, title, embedding <=> '[1,0,0]'::public.vector(3) AS distance
FROM eligible ORDER BY distance, doc_id LIMIT 10;
-- Expected fixture order: 102, 103. Not global corpus top-k, not HNSW evidence.
COMMIT;
