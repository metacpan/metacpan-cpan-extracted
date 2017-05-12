-- Revert robobot:p-auth-20161128164909 from pg

BEGIN;

DROP TABLE robobot.auth_permissions;

COMMIT;
