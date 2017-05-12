#!/bin/sh
LOG=logstress.log
rm -f $LOG
for i in 1 2 3 4
do
  perl -MData::Conveyor::Log -e'$l=Class::Scaffold::Log->instance(filename=>shift);$l->info("test $_") for 1..3000' $LOG &
done
wait
perl -lne'BEGIN{print "1..1"} $b="not ",last unless /^\d+\.\d+ test \d+$/; END{print $b."ok 1"}' $LOG
rm $LOG
