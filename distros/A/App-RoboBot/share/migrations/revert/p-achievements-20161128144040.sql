-- Revert robobot:p-achievements-20161128144040 from pg

BEGIN;

DROP TABLE robobot.achievement_nicks;
DROP TABLE robobot.achievements;

COMMIT;
