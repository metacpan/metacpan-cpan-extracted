-- PostgreSQL 18 skill lab. Synthetic data; disposable database only.
-- Source-reviewed example, not integration-tested during package creation.
-- psql script: run with -X and ON_ERROR_STOP. Read README before executing.
\set ON_ERROR_STOP on

-- Read-only. No extension installation, library loading, or role changes.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '10s';
SELECT version(), current_database(), session_user, current_user;
SELECT current_setting('server_version_num') AS server_version_num,
       current_setting('search_path') AS search_path;
SELECT e.extname, e.extversion, n.nspname AS extension_schema
FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
ORDER BY e.extname;
SELECT name, default_version, installed_version
FROM pg_available_extensions WHERE name IN ('vector', 'age') ORDER BY name;
SELECT name, setting, unit, source
FROM pg_settings
WHERE name IN ('shared_preload_libraries', 'work_mem', 'maintenance_work_mem',
               'max_connections', 'statement_timeout', 'lock_timeout',
               'transaction_isolation', 'row_security')
ORDER BY name;
SELECT rolname, rolsuper, rolbypassrls, rolcanlogin
FROM pg_roles WHERE rolname IN (current_user, session_user);
SELECT nspname, pg_get_userbyid(nspowner) AS owner, nspacl
FROM pg_namespace WHERE nspname IN ('public', 'ag_catalog', 'skill_lab', 'skill_graph');
SELECT current_setting('server_version_num')::integer BETWEEN 180000 AND 189999
       AS reviewed_pg18_baseline;
-- Pool mode, provider allowlist, source commits and ABI provenance cannot all be
-- inferred from these catalogs. Record them separately in the fingerprint.
COMMIT;
