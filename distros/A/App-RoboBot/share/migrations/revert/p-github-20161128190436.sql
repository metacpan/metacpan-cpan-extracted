-- Revert robobot:p-github-20161128190436 from pg

BEGIN;

DROP TABLE robobot.github_repo_channels;
DROP TABLE robobot.github_repos;

COMMIT;
