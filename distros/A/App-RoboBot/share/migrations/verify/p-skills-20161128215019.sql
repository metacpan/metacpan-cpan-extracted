-- Verify robobot:p-skills-20161128215019 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.skills_skills', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.skills_levels', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.skills_related', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.skills_nicks', 'insert');

ROLLBACK;
