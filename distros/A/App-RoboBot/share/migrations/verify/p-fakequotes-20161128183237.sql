-- Verify robobot:p-fakequotes-20161128183237 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.fakequotes_people', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.fakequotes_phrases', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.fakequotes_terms', 'insert');


ROLLBACK;
