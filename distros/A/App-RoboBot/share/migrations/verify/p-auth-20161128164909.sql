-- Verify robobot:p-auth-20161128164909 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.auth_permissions', 'insert');

ROLLBACK;
