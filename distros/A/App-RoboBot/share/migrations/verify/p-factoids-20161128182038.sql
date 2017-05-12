-- Verify robobot:p-factoids-20161128182038 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.factoids', 'insert');

ROLLBACK;
