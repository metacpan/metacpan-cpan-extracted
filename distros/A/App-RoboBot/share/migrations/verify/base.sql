-- Verify robobot:base on pg

BEGIN;

SELECT pg_catalog.has_schema_privilege('robobot', 'usage');

SELECT pg_catalog.has_table_privilege('robobot.nicks', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.networks', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.channels', 'insert');

ROLLBACK;
