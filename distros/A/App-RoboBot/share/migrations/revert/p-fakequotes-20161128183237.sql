-- Revert robobot:p-fakequotes-20161128183237 from pg

BEGIN;

DROP TABLE robobot.fakequotes_terms;
DROP TABLE robobot.fakequotes_phrases;
DROP TABLE robobot.fakequotes_people;

COMMIT;
