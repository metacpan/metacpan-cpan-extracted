-- Revert robobot:p-variables-20161128195027 from pg

BEGIN;

DROP TABLE robobot.global_vars;

COMMIT;
