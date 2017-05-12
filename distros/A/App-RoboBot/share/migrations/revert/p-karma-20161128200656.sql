-- Revert robobot:p-karma-20161128200656 from pg

BEGIN;

DROP TABLE robobot.karma_karma;

COMMIT;
