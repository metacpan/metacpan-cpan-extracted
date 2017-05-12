-- Verify robobot:p-macros-20161128210159 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.macros', 'insert');

ROLLBACK;
