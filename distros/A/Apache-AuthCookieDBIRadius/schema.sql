# $Id: schema.sql,v 1.1 2000/06/21 21:45:36 jacob Exp $
#
# Schema for creating the database tables for an authentication system.

CREATE TABLE users (
	user     CHAR(16) PRIMARY KEY,
	password CHAR(24)
);

CREATE TABLE groups (
	group CHAR(16),
	user CHAR(16)
);

