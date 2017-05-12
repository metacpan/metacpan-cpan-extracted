-- Revert robobot:p-thinge-20161128223332 from pg

BEGIN;

DROP TABLE robobot.thinge_thinge_tags;
DROP TABLE robobot.thinge_thinges;
DROP TABLE robobot.thinge_tags;
DROP TABLE robobot.thinge_types;

COMMIT;
