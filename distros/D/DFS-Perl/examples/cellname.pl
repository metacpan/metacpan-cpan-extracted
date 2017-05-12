#! /usr/local/bin/perl

use DCE::DFS;

if (defined($cellname = DCE::DFS::cellname('/dfs/'))) {
    print "DFS cellname is $cellname\n";
}
else {
    print "Unable to determine DFS cellname\n";
}
