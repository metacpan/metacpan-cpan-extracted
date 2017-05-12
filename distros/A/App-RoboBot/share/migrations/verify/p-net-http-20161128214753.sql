-- Verify robobot:p-net-http-20161128214753 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.net_http_log', 'insert');

ROLLBACK;
