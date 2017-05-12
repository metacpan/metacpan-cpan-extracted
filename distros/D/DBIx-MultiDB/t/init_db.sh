#!/bin/bash

rm /tmp/db[12].db 2>/dev/null

sqlite3 /tmp/db1.db <<SQL
	CREATE TABLE employee (
		id INTEGER PRIMARY KEY, 
		name VARCHAR(20),
		company_id INTEGER
	);

	INSERT INTO employee (id, name, company_id) VALUES (1, 'a1', 1);
	INSERT INTO employee (id, name, company_id) VALUES (2, 'a2', 1);
	INSERT INTO employee (id, name, company_id) VALUES (3, 'b1', 2);
	INSERT INTO employee (id, name, company_id) VALUES (4, 'b2', 2);
	INSERT INTO employee (id, name, company_id) VALUES (5, 'c1', 3);
	INSERT INTO employee (id, name, company_id) VALUES (6, 'c2', 3);
SQL

sqlite3 /tmp/db2.db <<SQL
	CREATE TABLE company (
		id INTEGER PRIMARY KEY, 
		name VARCHAR(20)
	);

	INSERT INTO company (id, name) VALUES (1, 'a');
	INSERT INTO company (id, name) VALUES (2, 'b');
	INSERT INTO company (id, name) VALUES (3, 'c');
SQL
