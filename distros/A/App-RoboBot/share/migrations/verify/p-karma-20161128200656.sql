-- Verify robobot:p-karma-20161128200656 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.karma_karma', 'insert');

ROLLBACK;
