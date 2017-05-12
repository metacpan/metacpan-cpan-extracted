#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: aggregate.pl <ftserver_name>\n";
    exit;
}

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($ftserver, $status) = $flserver->ftserver_by_name($ARGV[0]); $status and
    print "Error creating ftserver - $status\n" and exit;

while (1) {
    my ($aggr, $status) = $ftserver->aggregate;

    last if $status == $ftserver->status_endoflist;

    $status and print "Unable to create aggregate - $status\n" and exit;

    printf("(%s, %s, %d, %d, %d, %d)\n", $aggr->name, $aggr->device, $aggr->id, $aggr->type, $aggr->size, $aggr->free);
}
