#!/usr/bin/bash

BASE=/opt/projects/cpantesters

cd $BASE/uploads
mkdir -p logs
mkdir -p data

date_format="%Y/%m/%d %H:%M:%S"
echo `date +"$date_format"` "START" >>logs/uploads.log

perl bin/uploads.pl --config=data/uploads.ini -u -b >>logs/uploads.log 2>&1

echo `date +"$date_format"` "Compressing Uploads data..." >>logs/uploads.log

cd $BASE/dbx
rm -f uploads.*
cp $BASE/uploads/data/uploads.db .  ; gzip  uploads.db
cp $BASE/uploads/data/uploads.db .  ; bzip2 uploads.db
cp $BASE/uploads/data/uploads.csv . ; gzip  uploads.csv
cp $BASE/uploads/data/uploads.csv . ; bzip2 uploads.csv

mkdir -p /var/www/cpandevel/uploads
mv uploads.* /var/www/cpandevel/uploads

echo `date +"$date_format"` "STOP" >>logs/uploads.log
