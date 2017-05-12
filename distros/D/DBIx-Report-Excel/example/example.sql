/* This is SQLite example for DBIx::Report::Excel perl module.

Run following command to create test database to be used with example.pl script:

sqlite3 testdb < example.sql

(c), Dmytro Kovalov, 2009.

*/
DROP TABLE names;
BEGIN TRANSACTION;
CREATE TABLE "people" (first_name varchar(40), last_name varchar(40));
INSERT INTO "people" VALUES('Dmytro','Kovalov');
INSERT INTO "people" VALUES('Me','Again');
COMMIT;

DROP TABLE fruits;
BEGIN TRANSACTION;
CREATE TABLE "fruits" (f_name varchar(40), color varchar(40));
INSERT INTO "fruits" VALUES('apple','red');
INSERT INTO "fruits" VALUES('banana','yellow');
COMMIT;

