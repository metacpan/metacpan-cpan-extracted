-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- OPTIONAL, SEPARATE APPROVAL. Requires 02 and 04, AGE with verified RLS support.
-- EFFECTS: creates a CLUSTER-LEVEL role, grants access, enables policies in lab.
-- Run only as an authorized administrator in an isolated test cluster/database.
-- Existing role name causes failure; no role is modified or silently repurposed.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
BEGIN;
CREATE ROLE skill_lab_reader NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
GRANT USAGE ON SCHEMA skill_lab, skill_graph, ag_catalog, public TO skill_lab_reader;
GRANT SELECT ON skill_lab.document TO skill_lab_reader;
ALTER TABLE skill_lab.document ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_lab.document FORCE ROW LEVEL SECURITY;
CREATE POLICY document_tenant_read ON skill_lab.document FOR SELECT TO skill_lab_reader
USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::bigint);
-- Handle every EXISTING graph label, including base vertex/edge label relations.
-- Future labels need their own policy/grant migration before being exposed.
DO $policy$
DECLARE label_record record;
BEGIN
  FOR label_record IN
    SELECT n.nspname, c.relname
    FROM ag_catalog.ag_label l
    JOIN ag_catalog.ag_graph g ON g.graphid=l.graph
    JOIN pg_class c ON c.oid=l.relation
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE g.name='skill_graph'
  LOOP
    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO skill_lab_reader',
                   label_record.nspname,label_record.relname);
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY',
                   label_record.nspname,label_record.relname);
    EXECUTE format('ALTER TABLE %I.%I FORCE ROW LEVEL SECURITY',
                   label_record.nspname,label_record.relname);
    EXECUTE format(
      'CREATE POLICY tenant_read ON %I.%I FOR SELECT TO skill_lab_reader USING '
      || '(((properties::jsonb ->> ''tenant_id'')::bigint) = '
      || 'NULLIF(current_setting(''app.tenant_id'',true),'''')::bigint)',
      label_record.nspname,label_record.relname);
  END LOOP;
END;
$policy$;
COMMIT;
-- app.tenant_id is supplied by a TRUSTED service. A role able to issue arbitrary
-- SET statements can impersonate this context; the GUC is not authentication.
-- Direct application-role tests, write policies, new labels and pool mode still
-- need explicit validation. This is not a production-ready authorization design.
