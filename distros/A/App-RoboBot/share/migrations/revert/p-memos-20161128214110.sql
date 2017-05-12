-- Revert robobot:p-memos-20161128214110 from pg

BEGIN;

DROP TABLE robobot.memo_memos;

COMMIT;
