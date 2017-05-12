-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Feb  1 15:20:52 2011
-- 

BEGIN TRANSACTION;

--
-- Table: user
--
CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name character varying NOT NULL,
  password character varying
);

COMMIT;
