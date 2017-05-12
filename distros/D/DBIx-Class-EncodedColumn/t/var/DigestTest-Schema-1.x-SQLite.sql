--
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon May 17 13:22:05 2010
--


BEGIN TRANSACTION;

--
-- Table: test_bcrypt
--
CREATE TABLE test_bcrypt (
  id INTEGER PRIMARY KEY NOT NULL,
  bcrypt_1 text,
  bcrypt_2 text
);

--
-- Table: test_pgp
--
CREATE TABLE test_pgp (
  id INTEGER PRIMARY KEY NOT NULL,
  dummy_col char(43) NOT NULL,
  pgp_col_passphrase text,
  pgp_col_key text,
  pgp_col_key_ps text,
  pgp_col_rijndael256 text
);

--
-- Table: test_sha
--
CREATE TABLE test_sha (
  id INTEGER PRIMARY KEY NOT NULL,
  dummy_col char(43) NOT NULL,
  sha1_hex char(40),
  sha1_b64 char(27),
  sha256_hex char(64),
  sha256_b64 char(43),
  sha256_b64_salted char(57)
);

--
-- Table: test_whirlpool
--
CREATE TABLE test_whirlpool (
  id INTEGER PRIMARY KEY NOT NULL,
  whirlpool_hex char(128),
  whirlpool_b64 char(86)
);

--
-- Table: test_timestamp_order
--
CREATE TABLE test_timestamp_order (
  id INTEGER PRIMARY KEY NOT NULL,
  username   TEXT NOT NULL,
  password   TEXT NOT NULL,
  created    TEXT,
  updated    TEXT
);

COMMIT;
