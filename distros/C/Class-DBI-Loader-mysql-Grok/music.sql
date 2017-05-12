DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
	artistid	int(10) unsigned not null primary key auto_increment,
	name		char(255)
);
INSERT INTO artist (name) VALUES ('Apocryphal');

DROP TABLE IF EXISTS cd;
CREATE TABLE cd (
	cdid	int(10) unsigned not null primary key auto_increment,
	artist	int(10) unsigned not null,
	title	char(255) not null,
	reldate	date not null
);
INSERT INTO cd (artist,title,reldate) VALUES (1,'First', '2001-01-01');
INSERT INTO cd (artist,title,reldate) VALUES (1,'Second','2001-02-02');

DROP TABLE IF EXISTS liner_notes;
CREATE TABLE liner_notes (
	cd		int(10) unsigned not null primary key,
	notes	text,
	stamp	timestamp
);
INSERT INTO liner_notes (cd,notes) VALUES (1, 'Liner Notes for First');

DROP TABLE IF EXISTS time_table;
CREATE TABLE time_table (
	id					int(10) unsigned not null primary key auto_increment,
	artist 				int(10) unsigned not null,
	time_field time 	default '12:12:12',
	date_field date 	default '2005-01-01',
	datetime_field		datetime default '2005-01-01 12:12:12',
	timestamp_field		timestamp
);
INSERT INTO time_table (artist) VALUES (1);

DROP TABLE IF EXISTS style;
CREATE TABLE style (
	styleid	int(10) unsigned not null primary key auto_increment,
	style	char(30) not null
);
INSERT INTO style (style) VALUES ('Blues'),('Funk'),('Country');

DROP TABLE IF EXISTS style_ref;
CREATE TABLE style_ref (
	cd		int(10) unsigned not null,
	style	int(10) unsigned not null,
	primary key (cd,style)
);
INSERT INTO style_ref (cd,style) VALUES (1,1),(1,2),(1,3);
