-- Verify robobot:p-net-urls-20161128224203 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.urltitle_urls', 'insert');

ROLLBACK;
