-- Revert robobot:p-alarms-20161128153112 from pg

BEGIN;

DROP TABLE robobot.alarms_alarms;

COMMIT;
