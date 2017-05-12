#!/bin/bash

# PODNAME: station-sync.sh

RECORD_BASE=$1
STORAGE_SERVER=$2
STORAGE_BASE=$3
ROOM=$4
DATE=$5

RATE_LIMIT_KBPS="10240"

while true; do
    # don't run too frequently: rsync blips the CPU
    sleep 60

    RECORD_PATH="${RECORD_BASE}"
    
    if [ -z "${ROOM}" ]; then
        echo "no room specified"
        exit 1
    fi
    
    if [ ! -d "${RECORD_PATH}" ]; then
        echo "path does not exist: ${RECORD_PATH}"
        exit 1
    fi
    
    cd ${RECORD_PATH}
    
    # build list of sync files - exclude open files 
    LIST=()
    for i in *.dv; do
        fuser $i > /dev/null 2>&1
        RETVAL=$?
        if [ ${RETVAL} -eq 1 ]; then
            LIST+=(${i})
        fi
    done
    
    # rsync to storage server
    rsync -vaurq --bwlimit=${RATE_LIMIT_KBPS} ${LIST[*]} av@${STORAGE_SERVER}:${STORAGE_BASE}/${ROOM}/${DATE}/

done

__END__

=pod

=encoding UTF-8

=head1 NAME

station-sync.sh

=head1 VERSION

version 0.5

=head1 AUTHOR

Leon Wright < techman@cpan.org >

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Leon Wright.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
