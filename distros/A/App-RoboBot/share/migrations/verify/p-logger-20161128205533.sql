-- Verify robobot:p-logger-20161128205533 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.logger_log', 'insert');

ROLLBACK;
