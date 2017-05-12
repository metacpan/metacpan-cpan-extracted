#!/bin/sh

DIR=`dirname "$0"`
TESTDB="$DIR/test.db"

rm -f "$TESTDB"
sqlite3 "$TESTDB" <<EOF
CREATE TABLE test (
	id integer PRIMARY KEY NOT NULL,
	name text NOT NULL
);
EOF
