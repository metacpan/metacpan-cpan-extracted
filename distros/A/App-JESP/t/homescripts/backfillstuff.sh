#! /bin/sh

set -xe

echo "SELECT * FROM foobar;" | $WHICH_SQLITE3 $JESP_DATABASE
echo "Done with $JESP_DSN"
