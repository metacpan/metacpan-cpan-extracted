-- Revert robobot:p-autoreply-20161128171050 from pg

BEGIN;

DROP TABLE robobot.autoreply_autoreplies;

COMMIT;
