#! /usr/local/bin/perl

use DCE::DFS;

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

while (1) {
    my ($ftserver, $status) = $flserver->ftserver;

    last if $status == $flserver->status_endoflist;

    $status and print "Error creating ftserver - $status\n" and exit;

    print $ftserver->hostname . " (" . $ftserver->address . ")\n";
}
