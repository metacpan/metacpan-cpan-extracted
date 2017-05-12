-- Revert robobot:p-location-20161128204426 from pg

BEGIN;

DROP TABLE robobot.locations;

COMMIT;
