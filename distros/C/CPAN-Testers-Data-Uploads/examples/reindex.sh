#!/usr/bin/bash

BASE=/opt/projects/cpantesters
LOG=logs/uploads-reindex2.log

cd $BASE/uploads
mkdir -p logs
mkdir -p data

date_format="%Y/%m/%d %H:%M:%S"
echo `date +"$date_format"` "START" >>$LOG

perl bin/uploads.pl --config=data/uploads.ini --logfile=logs/upload-reindex.log -r >>$LOG 2>&1

echo `date +"$date_format"` "STOP" >>$LOG
