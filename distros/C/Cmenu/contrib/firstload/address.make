#!/bin/sh

# Script to make an address database

SQLHOST="-h bbs"
SQLDBASE="home"

echo "Address.make">>Logfile
echo "Recreating Addresses"
psql $SQLHOST $SQLDBASE <sql/address.db >/dev/null 2>>Logfile
echo "Filling with Address data"
psql $SQLHOST $SQLDBASE <data/address.dat >/dev/null 2>>Logfile
echo "Recreating Address Descriptions"
psql $SQLHOST $SQLDBASE <sql/addcat.db >/dev/null 2>>Logfile
echo "Filling with Descriptions"
psql $SQLHOST $SQLDBASE <data/addcat.dat >/dev/null 2>>Logfile

