-- Revert robobot:p-macros-20161128210159 from pg

BEGIN;

DROP TABLE robobot.macros;

COMMIT;
