-- Accounts table for use in JOIN tests --
CREATE TABLE accounts
(
	account_id INTEGER PRIMARY KEY AUTOINCREMENT,
	email VARCHAR(128) NOT NULL,
	created BIGINT(20) NOT NULL DEFAULT '0',
	modified BIGINT(20) NOT NULL DEFAULT '0',
	UNIQUE (email)
);

-- Standard table. --
CREATE TABLE tests
(
	test_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	account_id INTEGER DEFAULT NULL,
	created BIGINT(20) NOT NULL DEFAULT '0',
	modified BIGINT(20) NOT NULL DEFAULT '0',
	FOREIGN KEY (account_id) REFERENCES accounts(account_id),
	UNIQUE (name)
);

-- Table without a "created" field. --
CREATE TABLE no_created_tests
(
	test_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	modified BIGINT(20) NOT NULL DEFAULT '0',
	UNIQUE (name)
);

-- Table without a "modified" field. --
CREATE TABLE no_modified_tests
(
	test_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	created BIGINT(20) NOT NULL DEFAULT '0',
	UNIQUE (name)
);

-- Table with actual date fields --
CREATE TABLE date_tests
(
	test_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	created TEXT DEFAULT NULL,
	modified TEXT DEFAULT NULL,
	UNIQUE (name)
);
