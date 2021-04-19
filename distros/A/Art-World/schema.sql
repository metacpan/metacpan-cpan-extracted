PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE Agent
(
	id integer not null
		constraint Agent_pk
			primary key autoincrement,
	name text not null,
	reputation integer not null
);
INSERT INTO Agent VALUES(1,'Ezgi Göç',100000);
INSERT INTO Agent VALUES(2,'Ezgi Göç',100000);
INSERT INTO Agent VALUES(3,'Ezgi Göç',100000);
INSERT INTO Agent VALUES(4,'Ezgi Göç',100000);
INSERT INTO Agent VALUES(5,'Ezgi Göç',666);
INSERT INTO Agent VALUES(6,'Ezgi Göç',777);
INSERT INTO Agent VALUES(7,'Ezgi Göç',777);
INSERT INTO Agent VALUES(8,'Ezgi Göç',777);
INSERT INTO Agent VALUES(9,'Ezgi Göç',777);
INSERT INTO Agent VALUES(10,'Ezgi Göç',777);
INSERT INTO Agent VALUES(11,'Ezgi Göç',888);
INSERT INTO Agent VALUES(12,'Ezgi Göç',888);
INSERT INTO Agent VALUES(13,'Ezgi Göç',888);
INSERT INTO Agent VALUES(14,'Ezgi Göç',888);
INSERT INTO Agent VALUES(15,'Ezgi Göç',888);
INSERT INTO Agent VALUES(16,'Ezgi Göç',888);
INSERT INTO Agent VALUES(17,'Ezgi Göç',888);
INSERT INTO Agent VALUES(18,'Ezgi Göç',888);
INSERT INTO Agent VALUES(19,'Ezgi Göç',888);
INSERT INTO Agent VALUES(20,'Ezgi Göç',888);
INSERT INTO Agent VALUES(21,'Ezgi Göç',888);
INSERT INTO Agent VALUES(22,'Ezgi Göç',888);
INSERT INTO Agent VALUES(23,'Ezgi Göç',888);
CREATE TABLE Event
(
	id integer not null
		constraint Event_pk
			primary key autoincrement,
	datetime integer not null,
	title text
);
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES('Agent',23);
CREATE UNIQUE INDEX Agent_id_uindex
	on Agent (id);
CREATE UNIQUE INDEX Event_id_uindex
	on Event (id);
COMMIT;
