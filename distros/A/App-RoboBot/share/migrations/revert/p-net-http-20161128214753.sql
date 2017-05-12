-- Revert robobot:p-net-http-20161128214753 from pg

BEGIN;

DROP TABLE robobot.net_http_log;

COMMIT;
