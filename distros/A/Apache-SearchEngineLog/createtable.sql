/* Pipe this to your database to create an appropriate table */
CREATE TABLE hits (
	term   varchar(50) NOT NULL DEFAULT "",
	vhost  varchar(20) NOT NULL DEFAULT "",
	uri    varchar(50) NOT NULL DEFAULT "",
	domain varchar(20) NOT NULL DEFAULT "",
	date   datetime    NOT NULL DEFAULT "0000-00-00 00:00:00",
	INDEX byvhost (vhost),
	INDEX byuri (vhost,uri),
	INDEX byterm (vhost,term)
);

CREATE TABLE config (
	domain varchar(20) NOT NULL DEFAULT "",
	field  varchar(10) NOT NULL DEFAULT "",
	PRIMARY KEY(domain)
);
