#!/bin/sh

# Script to make an address database

SQLHOST="-h bbs"
SQLDBASE="home"

echo "Food.make" >>Logfile
echo "Recreating Food Databases"
psql $SQLHOST $SQLDBASE <sql/foodcat.db >/dev/null 2>>Logfile
psql $SQLHOST $SQLDBASE <data/foodcat.dat >/dev/null 2>>Logfile

psql $SQLHOST $SQLDBASE <sql/food.db >/dev/null 2>>Logfile
psql $SQLHOST $SQLDBASE <data/food.dat >/dev/null 2>>Logfile

psql $SQLHOST $SQLDBASE <sql/foodunit.db >/dev/null 2>>Logfile
psql $SQLHOST $SQLDBASE <data/foodunit.dat >/dev/null 2>>Logfile
