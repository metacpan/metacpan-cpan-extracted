#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: flserver_ftserver_by_name.pl <name>\n";
    exit;
}

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($ftserver, $status) = $flserver->ftserver_by_name($ARGV[0]); $status and
    print "Error creating ftserver - $status\n" and exit;

print $ftserver->hostname . " (" . $ftserver->address . ")\n";
