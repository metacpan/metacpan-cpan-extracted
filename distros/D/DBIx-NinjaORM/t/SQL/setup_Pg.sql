-- Accounts table for use in JOIN tests --
CREATE TABLE accounts
(
	account_id SERIAL,
	email VARCHAR(128) NOT NULL,
	created INTEGER NOT NULL DEFAULT '0',
	modified INTEGER NOT NULL default '0',
	PRIMARY KEY (account_id),
	CONSTRAINT unq_accounts_email UNIQUE (email)
);

-- Standard table. --
CREATE TABLE tests
(
	test_id SERIAL,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	account_id INTEGER DEFAULT NULL REFERENCES accounts(account_id),
	created INTEGER NOT NULL default '0',
	modified INTEGER NOT NULL default '0',
	PRIMARY KEY (test_id),
	CONSTRAINT unq_tests_name UNIQUE (name)
);

-- Table without a "created" field. --
CREATE TABLE no_created_tests
(
	test_id SERIAL,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	modified INTEGER NOT NULL default '0',
	PRIMARY KEY (test_id),
	CONSTRAINT unq_no_created_tests_name UNIQUE (name)
);

-- Table without a "modified" field. --
CREATE TABLE no_modified_tests
(
	test_id SERIAL,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	created INTEGER NOT NULL default '0',
	PRIMARY KEY (test_id),
	CONSTRAINT unq_no_modified_tests_name UNIQUE (name)
);

-- Table with actual date fields --
CREATE TABLE date_tests
(
	test_id SERIAL,
	name VARCHAR(64) NOT NULL,
	value VARCHAR(128) DEFAULT NULL,
	created TIMESTAMP DEFAULT NULL,
	modified TIMESTAMP DEFAULT NULL,
	PRIMARY KEY (test_id),
	CONSTRAINT unq_date_tests_name UNIQUE (name)
);
