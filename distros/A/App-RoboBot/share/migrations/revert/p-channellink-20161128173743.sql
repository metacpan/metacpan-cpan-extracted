-- Revert robobot:p-channellink-20161128173743 from pg

BEGIN;

DROP TABLE robobot.channel_links;

COMMIT;
