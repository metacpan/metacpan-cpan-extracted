-- Verify robobot:p-github-20161128190436 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.github_repos', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.github_repo_channels', 'insert');

ROLLBACK;
