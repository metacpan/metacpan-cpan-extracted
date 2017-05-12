This is aimed at showing how a SBS + DefaultScheduler works

#Configuration
edit examples/sbsconfig-examples-1.xml to put your own local machines (it can be a good idea, if you have not a cluster, to enter your local machine with different addresses (localhost, 123.156.78.90, hostname) to see sommething a bit more realistic...

#System status
#in a side term, to see every second the 
watch -n 1 ../scripts/sbs-scheduler-print.pl --config=sbsconfig-examples-1.xml

#to submit or dozen or so scripts on queue 'single'
../scripts/sbs-batch-submit.pl --config=sbsconfig-examples-1.xml  --queue=single --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh
#and on a higher priority queue
../scripts/sbs-batch-submit.pl --config=sbsconfig-examples-1.xml  --queue=single_high --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh

#to update
../scripts/sbs-scheduler-update.pl --config=sbsconfig-examples-1.xml

#to check data consistency (and solve main problems
../scripts/sbs-scheduler-check.pl

#to remove a job --config=sbsconfig-examples-1.xml
../scripts/sbs-batch-remove  --config=sbsconfig-examples-1.xml yourjobid


##############
#
# subiting scripts
#
##############