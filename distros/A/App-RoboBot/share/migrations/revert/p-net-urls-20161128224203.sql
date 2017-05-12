-- Revert robobot:p-net-urls-20161128224203 from pg

BEGIN;

DROP TABLE robobot.urltitle_urls;

COMMIT;
