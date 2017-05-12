#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 2) {
    print "Usage: crmount.pl <path> <fileset>\n";
}
else {
    if (my $status = DCE::DFS::crmount($ARGV[0], $ARGV[1])) {
	print "crmount failed - $status\n";
    }
}
