#!/bin/sh

DIR=`dirname "$0"`
TESTDB="$DIR/test.db"

rm -f "$TESTDB"
sqlite3 "$TESTDB" <<EOF
CREATE TABLE person (
	id integer primary key autoincrement,
	name text,
	age integer
);
INSERT INTO person ( name, age ) VALUES ( 'Alan', 42 );
INSERT INTO person ( name, age ) VALUES ( 'Bob', 27 );
INSERT INTO person ( name, age ) VALUES ( 'Charlie', 64 );
INSERT INTO person ( name, age ) VALUES ( 'Dave', 12 );
EOF
