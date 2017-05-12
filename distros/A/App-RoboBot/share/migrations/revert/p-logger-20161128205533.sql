-- Revert robobot:p-logger-20161128205533 from pg

BEGIN;

DROP TABLE robobot.logger_log;

COMMIT;
