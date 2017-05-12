#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: fid.pl <path>\n";
    exit;
}

my ($fid, $status) = DCE::DFS::fid($ARGV[0]); $status and
    print "Error creating fid - $status\n" and exit;

print "Fileset id = " . $fid->id . "\n";


