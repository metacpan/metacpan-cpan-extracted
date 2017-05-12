-- Verify robobot:p-markov-20161128212720 on pg

BEGIN;

SELECT pg_catalog.has_table_privilege('robobot.markov_phrases', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.markov_sentence_forms', 'insert');
SELECT pg_catalog.has_table_privilege('robobot.markov_neighbors', 'insert');

ROLLBACK;
