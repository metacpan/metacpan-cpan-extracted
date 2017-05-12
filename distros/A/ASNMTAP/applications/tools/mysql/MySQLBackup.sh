#!/bin/bash

#####################################
### MySQL Configuration Variables ### #####################################

# MySQL Hostname
DBHOST='localhost'

# MySQL Username
DBUSER='backup'

# MySQL Password
DBPASSWD='backup'

# Local Directory for Dump Files
LOCALDIR=/opt/backup/

# Prefix for offsite .tar file backup
TARPREFIX=mysql

#####################################
### Edit Below If Necessary ######### #####################################

cd $LOCALDIR
SUFFIX=`eval date +%y%m%d`

DBS=`/usr/local/mysql/bin/mysql -u$DBUSER -p$DBPASSWD -h$DBHOST -e"show databases"`

for DATABASE in $DBS
do
  if [ $DATABASE != "Database" ]; then
    FILENAME=$SUFFIX-$DATABASE.gz
    /usr/local/mysql/bin/mysqldump -u$DBUSER -p$DBPASSWD -h$DBHOST $DATABASE | /usr/local/bin/gzip --best > $LOCALDIR$FILENAME
  fi
done

tar -cf $TARPREFIX-$SUFFIX.tar $SUFFIX-*.gz

rm -f $SUFFIX-*.gz

exit 0
