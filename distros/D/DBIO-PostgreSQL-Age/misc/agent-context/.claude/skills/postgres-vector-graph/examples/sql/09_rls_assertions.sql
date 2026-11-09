-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Requires OPTIONAL 08; run as authorized administrator able to SET ROLE.
-- Read-only checks as non-owner, non-bypass skill_lab_reader. LOAD happens first.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
BEGIN READ ONLY;
SET LOCAL statement_timeout='10s';
SET LOCAL ROLE skill_lab_reader;
SET LOCAL app.tenant_id='1';
-- Positive and negative checks together avoid accepting a policy that hides all rows.
SELECT count(*)=6 AND count(*) FILTER (WHERE tenant_id<>1)=0 AS ok
FROM skill_lab.document \gset
\if :ok
\else
  \echo 'FAIL: relational tenant-one policy.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=6 AND count(*) FILTER (WHERE tenant_id::bigint<>1)=0 AS ok
FROM ag_catalog.cypher('skill_graph', $$
    MATCH (d:document) RETURN d.tenant_id
$$) AS g(tenant_id ag_catalog.agtype) \gset
\if :ok
\else
  \echo 'FAIL: labeled Cypher tenant-one policy.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=6 AND count(*) FILTER (WHERE tenant_id::bigint<>1)=0 AS ok
FROM ag_catalog.cypher('skill_graph', $$
    MATCH (d) RETURN d.tenant_id
$$) AS g(tenant_id ag_catalog.agtype) \gset
\if :ok
\else
  \echo 'FAIL: unlabeled Cypher policy; inspect base/label behavior.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=4 AND count(*) FILTER (WHERE tenant_id::bigint<>1)=0 AS ok
FROM ag_catalog.cypher('skill_graph', $$
    MATCH ()-[r:related]->() RETURN r.tenant_id
$$) AS g(tenant_id ag_catalog.agtype) \gset
\if :ok
\else
  \echo 'FAIL: edge Cypher policy.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=6 AND count(*) FILTER (
    WHERE (properties::jsonb ->> 'tenant_id')::bigint<>1
)=0 AS ok FROM skill_graph.document \gset
\if :ok
\else
  \echo 'FAIL: direct label SQL policy.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
-- The same document ID exists in both tenants. Context change must not retain T1.
SET LOCAL app.tenant_id='2';
SELECT count(*)=2 AND count(*) FILTER (WHERE tenant_id<>2)=0 AS ok
FROM skill_lab.document \gset
\if :ok
\else
  \echo 'FAIL: switched relational tenant context.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=2 AND count(*) FILTER (WHERE tenant_id::bigint<>2)=0 AS ok
FROM ag_catalog.cypher('skill_graph', $$
    MATCH (d:document) RETURN d.tenant_id
$$) AS g(tenant_id ag_catalog.agtype) \gset
\if :ok
\else
  \echo 'FAIL: switched graph tenant context.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SET LOCAL app.tenant_id='';
SELECT count(*)=0 AS ok FROM skill_lab.document \gset
\if :ok
\else
  \echo 'FAIL: empty tenant context must return no SQL rows.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
SELECT count(*)=0 AS ok FROM ag_catalog.cypher('skill_graph', $$
    MATCH (d) RETURN d.doc_id
$$) AS g(doc_id ag_catalog.agtype) \gset
\if :ok
\else
  \echo 'FAIL: empty tenant context must return no graph rows.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
ROLLBACK;
\echo 'PASS: selected RLS assertions; other query/write/pool paths remain untested.'
