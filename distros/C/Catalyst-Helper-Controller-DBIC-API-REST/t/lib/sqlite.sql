-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug  8 01:53:20 2006
-- 
BEGIN TRANSACTION;

--
-- Table: cd_to_producer
--
CREATE TABLE cd_to_producer (
  cd integer NOT NULL,
  producer integer NOT NULL,
  PRIMARY KEY (cd, producer)
);

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
-- Table: track
--
CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  position integer NOT NULL,
  title varchar(100) NULL,
  last_updated_on datetime NULL
);

--
-- Table: tags
--
CREATE TABLE tags (
  tagid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  tag varchar(100) NOT NULL
);

--
-- Table: producer
--
CREATE TABLE producer (
  producerid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);

COMMIT;
