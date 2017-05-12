-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon May 24 11:59:13 2010
-- 


BEGIN TRANSACTION;

--
-- Table: role
--

CREATE TABLE role (
  role_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(24) NOT NULL
);

CREATE UNIQUE INDEX unique_role_name ON role (name);

--
-- Table: user
--

CREATE TABLE user (
  user_id INTEGER PRIMARY KEY NOT NULL,
  email varchar(64) NOT NULL
);

CREATE UNIQUE INDEX user_email ON user (email);

--
-- Table: user_role
--

CREATE TABLE user_role (
  fk_user_id integer(8) NOT NULL,
  fk_role_id integer(8) NOT NULL,
  PRIMARY KEY (fk_user_id, fk_role_id)
);

CREATE INDEX user_role_idx_fk_role_id ON user_role (fk_role_id);

CREATE INDEX user_role_idx_fk_user_id ON user_role (fk_user_id);

COMMIT;
