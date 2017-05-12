-- 
-- Table: cd_to_producer
--
DROP TABLE IF EXISTS cd_to_producer;
CREATE TABLE cd_to_producer (
  cd integer NOT NULL,
  producer integer NOT NULL,
  PRIMARY KEY (cd, producer)
);

--
-- Table: artist
--
DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100)
);

--
-- Table: artist_washed_up
--
DROP TABLE IF EXISTS artist_washed_up;
CREATE TABLE artist_washed_up (
  fk_artistid INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: cd
--
DROP TABLE IF EXISTS cd;
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  title varchar(100) NOT NULL,
  year varchar(100) NOT NULL
);

--
-- Table: track
--
DROP TABLE IF EXISTS track;
CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  position integer NOT NULL,
  title varchar(100) NOT NULL,
  last_updated_on datetime NULL
);

--
-- Table: tags
--
DROP TABLE IF EXISTS tags;
CREATE TABLE tags (
  tagid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  tag varchar(100) NOT NULL
);

--
-- Table: producer
--
DROP TABLE IF EXISTS producer;
CREATE TABLE producer (
  producerid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);
