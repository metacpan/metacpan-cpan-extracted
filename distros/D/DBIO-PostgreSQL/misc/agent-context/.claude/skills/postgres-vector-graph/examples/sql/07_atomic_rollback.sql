-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02 and 04. Writes are rolled back. No persistent fixture change intended.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
-- Ensure assertions cannot accidentally pass/fail due to a preexisting fixture key.
SELECT NOT EXISTS (
    SELECT 1 FROM skill_lab.document WHERE tenant_id=1 AND doc_id=999
) AND NOT EXISTS (
    SELECT 1 FROM ag_catalog.cypher('skill_graph', $$
      MATCH (d:document) WHERE d.tenant_id=1 AND d.doc_id=999 RETURN d.doc_id
    $$) AS g(doc_id ag_catalog.agtype)
) AS ok \gset
\if :ok
\else
  \echo 'Key 999 already exists; use a clean disposable lab.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
BEGIN;
INSERT INTO skill_lab.document (tenant_id,doc_id,title,body,model_id,embedding)
VALUES (1,999,'Rollback fixture','This row must not survive.','demo-v1','[1,0,0]');
SELECT * FROM ag_catalog.cypher('skill_graph', $$
  CREATE (d:document {tenant_id:1,doc_id:999}) RETURN d.doc_id
$$) AS g(doc_id ag_catalog.agtype);
ROLLBACK;
SELECT NOT EXISTS (
    SELECT 1 FROM skill_lab.document WHERE tenant_id=1 AND doc_id=999
) AND NOT EXISTS (
    SELECT 1 FROM ag_catalog.cypher('skill_graph', $$
      MATCH (d:document) WHERE d.tenant_id=1 AND d.doc_id=999 RETURN d.doc_id
    $$) AS g(doc_id ag_catalog.agtype)
) AS ok \gset
\if :ok
  \echo 'PASS: SQL row and AGE vertex are both absent after rollback.'
\else
  \echo 'FAIL: cross-model rollback did not match expectations.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
