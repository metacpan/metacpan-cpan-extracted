#!/usr/bin/perl -w
use strict;

sub size_of_file {
    return -s $_[0];
}

sub main {
    my $LOG_FILE = $ENV{WEBSERVER_LOG} || '/var/log/apache/error.log';

    my $log_size_initally = size_of_file $LOG_FILE;
    die "Couldn't stat $LOG_FILE" if not defined $log_size_initally;

    for my $t (glob '*.t') {
        system 'perl', '-w', $t;
    }

    my $log_size_afterward = size_of_file $LOG_FILE;

    my $diff = $log_size_afterward - $log_size_initally;

    if ($diff) {
        print STDERR
            "Log grew by $diff, probably not good (best case: use of uninit, ",
            "worst case: security hole):\n";
        system 'tail', $LOG_FILE;
    }
}

main;
