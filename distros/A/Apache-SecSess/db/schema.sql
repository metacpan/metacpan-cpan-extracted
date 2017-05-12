\!#
\!# schema.sql - session manager account schema
\!#
\!# $Id: schema.sql,v 1.2 2002/04/13 02:29:41 pliam Exp $
\!#

\!#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

\!# users and related info:
\!#		name = full name
\!#		grpid = default group
\!#		status = lifecycle string (e.g. created->registered->disabled->retired)
\!#		creation = time of creation
create table Users (
	usrid				char(16) primary key,
	name				varchar,
	grpid				char(16),
	status				varchar,
	creation			integer
);

\!# groups of users (e.g. group ownership, access level, admin privileges, etc)
create table Groups (
	grpid				char(16) primary key,
	descr				varchar
);

\!# group membership (many-to-many)
create table UserGroup (
	usrid				char(16),
	grpid				char(16),
	unique (usrid, grpid)
);

\!#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

\!# authentication methods
\!# maxfail = # of consecutive failures before status 'disabled'
create table Authens (
	authid				char(16) primary key,
	descr				varchar,
	maxfail				integer
);

\!# user authentication data (e.g. passwords, certs, etc)
create table UserAuthen (
	usrid				char(16),
	authid				char(16),
	token				varchar,
	failcount			integer,
	unique (usrid, authid)
);

\!# Note: This data model, with a single string 'token', is overly simplistic 
\!# for things like challenge/response, multiple CA chaining, etc.
