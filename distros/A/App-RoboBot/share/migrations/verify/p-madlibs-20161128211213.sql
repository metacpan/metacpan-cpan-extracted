-- Verify robobot:p-madlibs-20161128211213 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.madlibs_madlibs', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.madlibs_results', 'insert');

ROLLBACK;
