-- Verify robobot:p-achievements-20161128144040 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.achievements', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.achievement_nicks', 'insert');

ROLLBACK;
