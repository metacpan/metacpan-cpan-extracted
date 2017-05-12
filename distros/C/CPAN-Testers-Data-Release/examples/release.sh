#!/usr/bin/bash

BASE=/opt/projects/cpantesters
LOG=/opt/projects/cpantesters/release/logs/release.log

cd $BASE/release
mkdir -p logs
mkdir -p data

date_format="%Y/%m/%d %H:%M:%S"
echo `date +"$date_format"` "START" >>$LOG

perl bin/release.pl --config=data/release.ini

echo `date +"$date_format"` "Compressing Release data..." >>$LOG

if [ -f $BASE/release/data/release.db ];
then

  cd $BASE/db
  cp $BASE/release/data/release.db .

  cd $BASE/dbx
  rm -f release.*

  echo `date +"$date_format"` ".. compressing with gzip" >>$LOG
  cp $BASE/release/data/release.db .  ; gzip  release.db

  echo `date +"$date_format"` ".. compressing with bzip" >>$LOG
  cp $BASE/release/data/release.db .  ; bzip2 release.db

  echo `date +"$date_format"` ".. compressed" >>$LOG

  mkdir -p /var/www/cpandevel/release
  mv release.* /var/www/cpandevel/release

fi

cd $BASE/release
echo `date +"$date_format"` "STOP" >>$LOG
