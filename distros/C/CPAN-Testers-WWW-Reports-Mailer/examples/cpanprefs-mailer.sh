#!/usr/bin/bash

cd /opt/projects/cpantesters/reports-mailer
mkdir -p logs

date_format="%Y/%m/%d %H:%M:%S"
echo `date +"$date_format"` "START" >>logs/xx.out
echo `date +"$date_format"` "START" >>logs/xx.err

# run the daily reports
perl bin/cpanreps-mailer --config=data/preferences-daily.ini --nomail >>logs/xx.out 2>>logs/xx.err

# run the named weekly reports
day=`date +"%a"`
perl bin/cpanreps-mailer --config=data/preferences-weekly.ini --mode=$day --nomail >>logs/xx.out 2>>logs/xx.err

# run the generic weekly on a Saturday morning
if [ `date +"%w"` -eq 6 ]; then
  perl bin/cpanreps-mailer --config=data/preferences-weekly.ini --nomail >>logs/xx.out 2>>logs/xx.err
fi

# run the monthly on the first day of the month
if [ `date +"%-d"` -eq 1 ]; then
  perl bin/cpanreps-mailer --config=data/preferences.ini --mode=monthly --logfile=logs/monthly-mailer.log --nomail >>logs/xx.out 2>>logs/xx.err
fi

# produce the individual reports
perl bin/cpanreps-mailer --config=data/preferences.ini --mode=reports --logfile=logs/reports-mailer.log --nomail >>logs/xx.out 2>>logs/xx.err

echo `date +"$date_format"` "STOP"  >>logs/xx.out
echo `date +"$date_format"` "STOP"  >>logs/xx.err

