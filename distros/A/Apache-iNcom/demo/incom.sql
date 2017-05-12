CREATE TABLE sessions (
	id	    CHAR(32) PRIMARY KEY,
	length	    INT,
	a_session   TEXT,
	created	    TIMESTAMP DEFAULT 'now()',
	last_update TIMESTAMP DEFAULT 'now()'
);

CREATE TABLE userdb (
	uid	    SERIAL PRIMARY KEY,
	username    CHAR(32) UNIQUE,
	password    CHAR(32),
	carts	    TEXT,
	visits	    INT DEFAULT 0,
	last_login  TIMESTAMP DEFAULT 'now()',
	last_host   CHAR(128),
	fullname    CHAR(128),
	b_name	    CHAR(128),
	b_address   CHAR(128),
	b_city	    CHAR(128),
	b_state	    CHAR(32),
	b_country   CHAR(2),
	b_zipcode   CHAR(32),
	s_address   CHAR(128),
	s_city	    CHAR(128),
	s_state	    CHAR(32),
	s_country   CHAR(2),
	s_zipcode   CHAR(32),
	email	    CHAR(128),
	day_phone   CHAR(20),
	night_phone CHAR(20)
);

CREATE UNIQUE INDEX userdb_idx ON userdb (username);

CREATE TABLE groupdb (
	gid	    SERIAL PRIMARY KEY,
	groupname   CHAR(32) UNIQUE
);
CREATE UNIQUE INDEX groupdb_idx ON groupdb (groupname);

CREATE TABLE groupmembers (
	gid	    INT REFERENCES groupdb,
	uid	    INT REFERENCES userdb,
	PRIMARY KEY (gid,uid)
);

CREATE INDEX group2users_idx ON groupmembers (gid);
CREATE INDEX user2groups_idx ON groupmembers (uid);

CREATE TABLE user_acl (
	uid	    INT REFERENCES userdb,
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (uid,target,privilege)
);
CREATE INDEX user_acl_uid_idx	 ON user_acl (uid);
CREATE INDEX user_acl_target_idx ON user_acl (target);

CREATE TABLE group_acl (
	gid	    INT REFERENCES groupdb,
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (gid,target,privilege)
);
CREATE INDEX group_acl_uid_idx	  ON group_acl (gid);
CREATE INDEX group_acl_target_idx ON group_acl (target);

CREATE TABLE default_acl (
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (target,privilege)
);
CREATE INDEX default_acl_target_idx ON user_acl (target);

