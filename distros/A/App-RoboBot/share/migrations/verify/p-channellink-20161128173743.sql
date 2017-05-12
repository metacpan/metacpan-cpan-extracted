-- Verify robobot:p-channellink-20161128173743 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.channel_links', 'insert');

ROLLBACK;
