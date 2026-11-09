-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires 02 plus AGE. EFFECTS: a new graph, two labels, eight vertices, five edges.
-- Direct/session-pooled administrator connection; omit LOAD only after verifying
-- equivalent server preloading. Do not silently reuse a preexisting graph.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
BEGIN;
SELECT ag_catalog.create_graph('skill_graph');
SELECT * FROM ag_catalog.cypher('skill_graph', $$
  CREATE (a:document {tenant_id:1, doc_id:101}),
         (b:document {tenant_id:1, doc_id:102}),
         (c:document {tenant_id:1, doc_id:103}),
         (d:document {tenant_id:1, doc_id:104}),
         (e:document {tenant_id:1, doc_id:105}),
         (f:document {tenant_id:1, doc_id:106}),
         (g:document {tenant_id:2, doc_id:101}),
         (h:document {tenant_id:2, doc_id:202}),
         (a)-[:related {tenant_id:1, strength:0.9, evidence_id:'source-101-102'}]->(b),
         (a)-[:related {tenant_id:1, strength:0.8, evidence_id:'source-101-103'}]->(c),
         (b)-[:related {tenant_id:1, strength:0.7, evidence_id:'source-102-105'}]->(e),
         (c)-[:related {tenant_id:1, strength:0.6, evidence_id:'source-103-104'}]->(d),
         (g)-[:related {tenant_id:2, strength:1.0, evidence_id:'private-101-202'}]->(h)
  RETURN a.doc_id
$$) AS g(doc_id ag_catalog.agtype);
COMMIT;
-- Same doc_id=101 in both tenants deliberately tests composite-key boundaries.
