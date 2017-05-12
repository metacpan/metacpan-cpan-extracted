-- Verify robobot:p-autoreply-20161128171050 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.autoreply_autoreplies', 'insert');

ROLLBACK;
