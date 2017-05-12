#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: quota.pl <path>\n";
    exit;
}

my ($fid, $status) = DCE::DFS::fid($ARGV[0]); $status and
    print "Error creating fid - $status\n" and exit;

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($fileset, $status) = $flserver->fileset_by_id($fid); $status and
    print "Error creating fileset - $status\n" and exit;

my ($quota, $used, $status) = $fileset->quota; $status and
    print "Error obtaining quota - $status\n" and exit;

print "quota: $quota, used: $used\n";


