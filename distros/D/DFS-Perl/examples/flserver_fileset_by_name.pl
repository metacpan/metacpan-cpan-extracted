#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: flserver_fileset_by_name.pl <name>\n";
    exit;
}

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($fileset, $status) = $flserver->fileset_by_name($ARGV[0]); $status and
    print "Error creating fileset - $status\n" and exit;

print $fileset->name . "\n";
