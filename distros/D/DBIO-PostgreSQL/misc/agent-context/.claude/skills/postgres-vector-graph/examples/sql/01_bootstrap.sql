-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- EFFECTS: creates extensions if absent; loads AGE on this backend.
-- Approval: database administrator; exact binaries must already be installed.
SELECT current_setting('server_version_num')::integer BETWEEN 180000 AND 189999 AS ok \gset
\if :ok
\else
  \echo 'This lab targets PG18. Revalidate and adapt before using another major.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS age;
SELECT n.nspname = 'public' AS ok
FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace
WHERE e.extname='vector' \gset
\if :ok
\else
  \echo 'Lab SQL expects vector in public; do not relocate an existing extension automatically.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
-- Self-hosted/direct or session-pooled lab. Managed preloading may replace LOAD;
-- do not grant superuser to an application to make this work.
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
SELECT extname, extversion FROM pg_extension WHERE extname IN ('age','vector');
-- AGE 1.8 JSONB-cast behavioral gate; it intentionally fails on unsupported builds.
SELECT ('{"gate":true}'::jsonb::ag_catalog.agtype)::jsonb = '{"gate":true}'::jsonb AS ok \gset
\if :ok
\else
  \echo 'Required AGE JSONB conversion behavior is missing.'
  DO $assert$ BEGIN RAISE EXCEPTION 'Lab assertion failed; see diagnostic above'; END; $assert$;
\endif
