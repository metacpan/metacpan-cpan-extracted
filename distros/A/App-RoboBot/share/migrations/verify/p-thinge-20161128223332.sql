-- Verify robobot:p-thinge-20161128223332 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.thinge_types', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.thinge_tags', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.thinge_thinges', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.thinge_thinge_tags', 'insert');

ROLLBACK;
