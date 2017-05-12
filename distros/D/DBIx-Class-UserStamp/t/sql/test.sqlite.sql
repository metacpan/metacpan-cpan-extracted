BEGIN TRANSACTION;
CREATE TABLE test_user (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  u_created integer NOT NULL,
  u_updated integer NOT NULL
);
CREATE TABLE test_accessor (
  pk1 INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(128) NOT NULL,
  u_created integer NOT NULL,
  u_updated integer NOT NULL
);
COMMIT;
