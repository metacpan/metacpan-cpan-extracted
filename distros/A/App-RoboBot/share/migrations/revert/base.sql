-- Revert robobot:base from pg

BEGIN;

DROP TABLE robobot.channels;
DROP TABLE robobot.networks;
DROP TABLE robobot.nicks;

DROP SCHEMA robobot;

COMMIT;
