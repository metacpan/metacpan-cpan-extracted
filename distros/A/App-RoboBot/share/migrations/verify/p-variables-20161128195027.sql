-- Verify robobot:p-variables-20161128195027 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.global_vars', 'insert');

ROLLBACK;
