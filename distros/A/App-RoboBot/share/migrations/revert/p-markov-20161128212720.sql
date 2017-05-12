-- Revert robobot:p-markov-20161128212720 from pg

BEGIN;

DROP TABLE robobot.markov_neighbors;
DROP TABLE robobot.markov_sentence_forms;
DROP TABLE robobot.markov_phrases;

COMMIT;
