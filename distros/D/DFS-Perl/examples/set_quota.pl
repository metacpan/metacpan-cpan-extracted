#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 2) {
    print "Usage: set_quota.pl <path> <kbytes>\n";
    exit;
}

my ($fid, $status) = DCE::DFS::fid($ARGV[0]); $status and
    print "Error creating fid - $status\n" and exit;

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($fileset, $status) = $flserver->fileset_by_id($fid); $status and
    print "Error creating fileset - $status\n" and exit;

my $status = $fileset->set_quota($ARGV[1]); $status and
    print "Error setting quota - $status\n" and exit;



