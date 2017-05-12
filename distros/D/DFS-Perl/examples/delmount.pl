#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: delmount.pl <path>\n";
}
else {
    if (my $status = DCE::DFS::delmount($ARGV[0])) {
	print "delmount failed - $status\n";
    }
}
