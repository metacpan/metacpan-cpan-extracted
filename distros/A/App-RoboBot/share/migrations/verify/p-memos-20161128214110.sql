-- Verify robobot:p-memos-20161128214110 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.memo_memos', 'insert');

ROLLBACK;
