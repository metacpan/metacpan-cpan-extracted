-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug  8 01:53:20 2006
-- 
BEGIN TRANSACTION;

--
-- Table: artist
--
CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100)
);


--
-- Table: cd
--
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  title varchar(100) NOT NULL,
  year varchar(100) NOT NULL
);

--
-- Table: friend
--
CREATE TABLE friend (
  friendid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

COMMIT;
