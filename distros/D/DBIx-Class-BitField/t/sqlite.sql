-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Aug 16 19:46:28 2009
-- 


BEGIN TRANSACTION;

--
-- Table: item
--
CREATE TABLE item (
  id INTEGER PRIMARY KEY NOT NULL,
  bitfield integer NOT NULL DEFAULT '0',
  bitfield2 integer DEFAULT '0'
);

--
-- Table: subclass_1
--
CREATE TABLE subclass_1 (
  id  NOT NULL,
  status Integer NOT NULL DEFAULT '0',
  PRIMARY KEY (id)
);

--
-- Table: subclass_2
--
CREATE TABLE subclass_2 (
  id  NOT NULL,
  status Integer NOT NULL DEFAULT '0',
  PRIMARY KEY (id)
);

COMMIT;
