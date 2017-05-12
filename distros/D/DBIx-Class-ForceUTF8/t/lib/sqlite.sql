-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug  8 01:53:20 2006
-- 
BEGIN TRANSACTION;

--
-- Table: cd
--
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  title varchar(100) NOT NULL,
  year varchar(100) NOT NULL
);


CREATE UNIQUE INDEX cd_artist_title_cd on cd (artist, title);
COMMIT;
