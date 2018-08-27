-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Apr 22 13:09:39 2018
-- 

BEGIN TRANSACTION;

--
-- Table: metabase_user
--
DROP TABLE metabase_user;

CREATE TABLE metabase_user (
  id INTEGER PRIMARY KEY NOT NULL,
  resource char(50) NOT NULL,
  fullname varchar NOT NULL,
  email varchar
);

CREATE UNIQUE INDEX metabase_user_resource ON metabase_user (resource);

--
-- Table: perl_version
--
DROP TABLE perl_version;

CREATE TABLE perl_version (
  version varchar(255) NOT NULL,
  perl varchar(32),
  patch tinyint(1) NOT NULL DEFAULT 0,
  devel tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (version)
);

--
-- Table: test_report
--
DROP TABLE test_report;

CREATE TABLE test_report (
  id char(36) NOT NULL,
  created datetime NOT NULL,
  report JSON NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: uploads
--
DROP TABLE uploads;

CREATE TABLE uploads (
  uploadid INTEGER PRIMARY KEY NOT NULL,
  type varchar NOT NULL,
  author varchar NOT NULL,
  dist varchar NOT NULL,
  version varchar NOT NULL,
  filename varchar NOT NULL,
  released bigint NOT NULL
);

--
-- Table: cpanstats
--
DROP TABLE cpanstats;

CREATE TABLE cpanstats (
  id INTEGER PRIMARY KEY NOT NULL,
  guid char(36) NOT NULL,
  state enum NOT NULL,
  postdate mediumint NOT NULL,
  tester varchar(255) NOT NULL,
  dist varchar(255) NOT NULL,
  version varchar(255) NOT NULL,
  platform varchar(255) NOT NULL,
  perl varchar(255) NOT NULL,
  osname varchar(255) NOT NULL,
  osvers varchar(255) NOT NULL,
  fulldate varchar(32) NOT NULL,
  type tinyint NOT NULL,
  uploadid int NOT NULL,
  FOREIGN KEY (uploadid) REFERENCES uploads(uploadid)
);

CREATE INDEX cpanstats_idx_uploadid ON cpanstats (uploadid);

CREATE UNIQUE INDEX guid ON cpanstats (guid);

--
-- Table: ixlatest
--
DROP TABLE ixlatest;

CREATE TABLE ixlatest (
  dist varchar NOT NULL,
  author varchar NOT NULL,
  version varchar NOT NULL,
  released bigint NOT NULL,
  oncpan int NOT NULL,
  uploadid int NOT NULL,
  PRIMARY KEY (dist, author),
  FOREIGN KEY (uploadid) REFERENCES uploads(uploadid)
);

CREATE INDEX ixlatest_idx_uploadid ON ixlatest (uploadid);

--
-- Table: release_data
--
DROP TABLE release_data;

CREATE TABLE release_data (
  dist varchar NOT NULL,
  version varchar NOT NULL,
  id int NOT NULL,
  guid char(36) NOT NULL,
  oncpan int NOT NULL,
  distmat int NOT NULL,
  perlmat int NOT NULL,
  patched int NOT NULL,
  pass int NOT NULL,
  fail int NOT NULL,
  na int NOT NULL,
  unknown int NOT NULL,
  uploadid int NOT NULL,
  PRIMARY KEY (id, guid),
  FOREIGN KEY (uploadid) REFERENCES uploads(uploadid)
);

CREATE INDEX release_data_idx_uploadid ON release_data (uploadid);

--
-- Table: release_summary
--
DROP TABLE release_summary;

CREATE TABLE release_summary (
  dist varchar NOT NULL,
  version varchar NOT NULL,
  id int NOT NULL,
  guid char(36) NOT NULL,
  oncpan int NOT NULL,
  distmat int NOT NULL,
  perlmat int NOT NULL,
  patched int NOT NULL,
  pass int NOT NULL,
  fail int NOT NULL,
  na int NOT NULL,
  unknown int NOT NULL,
  uploadid int NOT NULL,
  FOREIGN KEY (guid) REFERENCES cpanstats(guid),
  FOREIGN KEY (uploadid) REFERENCES uploads(uploadid)
);

CREATE INDEX release_summary_idx_guid ON release_summary (guid);

CREATE INDEX release_summary_idx_uploadid ON release_summary (uploadid);

COMMIT;
