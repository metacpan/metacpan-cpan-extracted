#!/bin/bash
#
# generate-backpan-indexes.sh
#
# This is BARBIE's script that is used to generate the indexes
# on the CPAN Testers BackPAN mirror:
#
#   http://backpan.cpantesters.org
#

BASE=/opt/projects/pause
LOCK=backpan.lock
LOG=logs/backpan.log

date_format="%Y/%m/%d %H:%M:%S"

cd $BASE

if [ -f $LOCK ]
then
    echo `date +"$date_format"` "BACKPAN update is already running" >>$LOG
else
    touch $LOCK

    echo `date +"$date_format"` "START" >>$LOG
    echo `date +"$date_format"` "copying files from CPAN to BACKPAN" >>$LOG
    rsync --exclude CHECKSUMS -vrptgx /opt/projects/CPAN/authors/id/ /opt/projects/BACKPAN/authors/id/ >>$LOG 2>&1

    echo `date +"$date_format"` "creating BACKPAN indices" >>$LOG
    /usr/local/bin/create-backpan-index -b=/opt/projects/BACKPAN -o=backpan-full-index.txt
    /usr/local/bin/create-backpan-index -b=/opt/projects/BACKPAN -r -o=backpan-releases-index.txt
    /usr/local/bin/create-backpan-index -b=/opt/projects/BACKPAN -r -order dist -o=backpan-releases-by-dist-index.txt
    /usr/local/bin/create-backpan-index -b=/opt/projects/BACKPAN -r -order author -o=backpan-releases-by-age-index.txt
    /usr/local/bin/create-backpan-index -b=/opt/projects/BACKPAN -r -order age -o=backpan-releases-by-author-index.txt

    echo `date +"$date_format"` "gzipping BACKPAN indices" >>$LOG
    gzip backpan-full-index.txt
    gzip backpan-releases-index.txt
    gzip backpan-releases-by-dist-index.txt
    gzip backpan-releases-by-age-index.txt
    gzip backpan-releases-by-author-index.txt

    mv backpan*index.txt.gz /opt/projects/BACKPAN

    echo `date +"$date_format"` "STOP" >>$LOG
    rm $LOCK
fi

