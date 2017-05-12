-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Sep  5 17:00:32 2010
-- 

;
BEGIN TRANSACTION;
--
-- Table: test
--
CREATE TABLE test (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  t_created datetime NOT NULL,
  t_updated datetime NOT NULL
);
--
-- Table: test_date
--
CREATE TABLE test_date (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  t_created date NOT NULL,
  t_updated date NOT NULL
);
--
-- Table: test_datetime
--
CREATE TABLE test_datetime (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  t_created datetime NOT NULL,
  t_updated datetime NOT NULL
);
--
-- Table: test_time
--
CREATE TABLE test_time (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  t_created timestamp NOT NULL,
  t_updated timestamp NOT NULL
);
COMMIT;
