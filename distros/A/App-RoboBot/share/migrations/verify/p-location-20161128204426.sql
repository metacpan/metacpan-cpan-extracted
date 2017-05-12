-- Verify robobot:p-location-20161128204426 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.locations', 'insert');

ROLLBACK;
