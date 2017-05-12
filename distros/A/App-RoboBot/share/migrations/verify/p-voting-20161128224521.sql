-- Verify robobot:p-voting-20161128224521 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.voting_polls', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.voting_poll_choices', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.voting_votes', 'insert');

ROLLBACK;
