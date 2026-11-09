-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 01. EFFECTS: new schema, tables, indexes, eight synthetic documents.
-- One-time setup: fails rather than silently reusing existing skill_lab objects.
BEGIN;
SET LOCAL search_path = pg_catalog, ag_catalog, public;
CREATE SCHEMA skill_lab;
CREATE TABLE skill_lab.document (
    tenant_id bigint NOT NULL,
    doc_id bigint NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    model_id text NOT NULL CHECK (model_id = 'demo-v1'),
    source_version bigint NOT NULL DEFAULT 1 CHECK (source_version > 0),
    embedding public.vector(3) NOT NULL,
    fts tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english'::regconfig, title), 'A') ||
        setweight(to_tsvector('english'::regconfig, body), 'B')
    ) STORED,
    PRIMARY KEY (tenant_id, doc_id),
    CHECK (public.vector_norm(embedding) > 0)
);
INSERT INTO skill_lab.document (tenant_id, doc_id, title, body, model_id, embedding) VALUES
 (1,101,'PostgreSQL vector search','Semantic retrieval with pgvector and SQL indexes.','demo-v1','[1,0,0]'),
 (1,102,'Graph retrieval','Apache AGE connects evidence through graph relationships.','demo-v1','[0.9,0.1,0]'),
 (1,103,'Hybrid search','Combine lexical full text search with semantic vector search.','demo-v1','[0.8,0.2,0]'),
 (1,104,'Backup operations','Restore databases and test extension compatibility.','demo-v1','[0.2,0.8,0]'),
 (1,105,'Tenant security','Policies isolate records and graph edges.','demo-v1','[0.3,0.7,0.1]'),
 (1,106,'Garden notes','Tomatoes need water and sunlight.','demo-v1','[0,0,1]'),
 (2,101,'Private tenant two','A confidential vector search record.','demo-v1','[1,0,0]'),
 (2,202,'Private graph document','Only tenant two should see this relationship.','demo-v1','[0.99,0.01,0]');
CREATE INDEX document_tenant_model_idx ON skill_lab.document (tenant_id, model_id);
CREATE INDEX document_fts_idx ON skill_lab.document USING gin (fts);
CREATE INDEX document_embedding_hnsw_idx
    ON skill_lab.document USING hnsw (embedding public.vector_cosine_ops);
ANALYZE skill_lab.document;
COMMIT;
-- Vectors encode a hand-made fixture, not real language-model embeddings.
-- Eight rows do not establish ANN performance; a sequential scan may be optimal.
