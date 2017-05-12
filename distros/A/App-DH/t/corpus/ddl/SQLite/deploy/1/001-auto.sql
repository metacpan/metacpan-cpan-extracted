--
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Jun 26 11:16:06 2015
--

;
BEGIN TRANSACTION;
--
-- Table: kitten
--
CREATE TABLE kitten (
  kitten_id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL
);
COMMIT;
