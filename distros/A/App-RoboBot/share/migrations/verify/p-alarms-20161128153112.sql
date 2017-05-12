-- Verify robobot:p-alarms-20161128153112 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.alarms_alarms', 'insert');

ROLLBACK;
