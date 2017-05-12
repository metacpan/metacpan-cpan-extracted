# $Id: setup-mysql.sql,v 1.11 2003/10/03 16:54:12 clajac Exp $

DROP DATABASE IF EXISTS cpanxr;
CREATE DATABASE IF NOT EXISTS cpanxr;

USE cpanxr;

# Entries for all distributions and their entry time
CREATE TABLE distributions (
	id	INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	path	varchar(255) BINARY NOT NULL,
	ts	TIMESTAMP NOT NULL
);

# Entries for all files and their entry time
CREATE TABLE files (
	id	INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	dist_id	INT NOT NULL,
	path	varchar(255) BINARY NOT NULL,
	symbol_id INT NOT NULL,
	type	TINYINT UNSIGNED NOT NULL,
	loc	INT,
	ts	TIMESTAMP NOT NULL
);

CREATE TABLE symbols (
	id	INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	symbol	varchar(255) BINARY NOT NULL
);

CREATE TABLE connections (
	symbol_id	INT NOT NULL,
	file_id		INT NOT NULL,
	line_no		INT NOT NULL,
	symbol_offset	INT NOT NULL,
	type		TINYINT UNSIGNED NOT NULL,
	package_id	INT NULL,
	caller_id	INT NULL,
	caller_sub_id	INT NULL
);