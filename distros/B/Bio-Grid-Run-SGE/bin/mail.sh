#!/bin/csh
# qsub -hold_jid array_job_id -N name mail.sh

set comment = "job_finished_$SGE_TASK_ID-$JOB_ID-$JOB_NAME"
set mail_address = $1
echo "." | mail -s $comment`date +" (%a_%d-%m-%y,%H:%M:%S)"` `echo $mail_address`
