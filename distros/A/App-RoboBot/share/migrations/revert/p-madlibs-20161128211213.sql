-- Revert robobot:p-madlibs-20161128211213 from pg

BEGIN;

DROP TABLE robobot.madlibs_results;
DROP TABLE robobot.madlibs_madlibs;

COMMIT;
