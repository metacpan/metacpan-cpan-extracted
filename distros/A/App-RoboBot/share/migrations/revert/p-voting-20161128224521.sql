-- Revert robobot:p-voting-20161128224521 from pg

BEGIN;

DROP TABLE robobot.voting_votes;
DROP TABLE robobot.voting_poll_choices;
DROP TABLE robobot.voting_polls;

COMMIT;
