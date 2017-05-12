#! /usr/local/bin/perl

use DCE::DFS;

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

while (1) {
    my ($ftserver, $status) = $flserver->ftserver;

    last if $status == $flserver->status_endoflist;

    $status and print "Error creating ftserver - $status\n" and exit;

    $flserver->fileset_mask_ftserver($ftserver);
    
    print "ftserver " . $ftserver->hostname . "\n";

    while (1) {
	my ($aggr, $status) = $ftserver->aggregate;

	last if $status == $ftserver->status_endoflist;

	$status and print "Error creating aggregate - $status\n" and exit;

	print "     aggregate " . $aggr->name . "\n";

	$flserver->fileset_mask_aggregate($aggr);

	while (1) {
	    my ($fileset, $status) = $flserver->fileset;
	    
	    last if $status == $flserver->status_endoflist;
	    
	    $status and print "Error creating fileset - $status\n" and exit;
	    
	    print "          " . $fileset->name . "\n";
	}
	print "\n";
    }
    print "\n";

    $flserver->fileset_reset;
}
