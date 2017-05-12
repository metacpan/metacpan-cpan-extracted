#!/bin/sh

# createusergroup.sh

set -x

DBDIR="/path/to/db"
LIBDIR="dump_directory=/path/to/app/lib"

sqlite3 --echo $DBDIR/usergroupdb < usergroup.sqlite
dbicdump -o $LIBDIR Usergroup::Schema dbi:SQLite:$DBDIR/usergroupdb
