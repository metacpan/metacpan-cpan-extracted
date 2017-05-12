-- Revert robobot:p-factoids-20161128182038 from pg

BEGIN;

DROP TABLE robobot.factoids;

COMMIT;
