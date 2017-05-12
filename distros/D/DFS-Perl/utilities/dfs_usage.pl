#!/usr/local/bin/perl
#
# Paul Henson <henson@acm.org>
# California State Polytechnic University, Pomona
#
# Copyright (c) 1997,1998,1999 Paul Henson -- see COPYRIGHT file for details
#

use DCE::DFS;

$| = 1;

my $verbosity = shift || 4;

my ($flserver, $status) = DCE::DFS::flserver(); $status and
    print "Error creating flserver object: $status \n\n" and exit;

my $cellname = DCE::DFS::cellname("/:/");

print "DFS usage report for " . $cellname . "\n";
print "---------------------";
for (my $i = 0; $i < length($cellname); $i++) { print "-"; }
print "\n\n";

my $cell_ftservers = 0;
my $cell_aggrs = 0;
my $cell_size = 0;
my $cell_used = 0;
my $cell_quota = 0;
my $cell_rw = 0;
my $cell_ro = 0;
my $cell_rpd = 0;
my $cell_wpd = 0;
my $cell_seconds = 0;

while (1) {
    my ($ftserver, $status) = $flserver->ftserver;

    last if ($status == $flserver->status_endoflist);

    $status and print "error enumerating ftservers - $status\n" and exit;

    $cell_ftservers++;

    print "  Fileserver " . $ftserver->hostname . " (" . $ftserver->address . ")\n\n" if $verbosity > 0;

    $flserver->fileset_reset;
    $flserver->fileset_mask_ftserver($ftserver);
    
    my $ftserver_aggrs = 0;
    my $ftserver_size = 0;
    my $ftserver_used = 0;
    my $ftserver_quota = 0;
    my $ftserver_rw = 0;
    my $ftserver_ro = 0;
    my $ftserver_reads = 0;
    my $ftserver_writes = 0;
    my $ftserver_seconds = 0;

    while (1) {

	my ($aggr, $status) = $ftserver->aggregate;

	last if ($status == $ftserver->status_endoflist);

	$status and print "error enumerating aggregates - $status\n" and exit;

	$ftserver_aggrs++;
	$ftserver_size += $aggr->size;

	printf("   Aggregate %s (id %d, device %s, type %d, size %s)\n\n",
	       $aggr->name, $aggr->id, $aggr->device, $aggr->type, fmt_size($aggr->size)) if $verbosity > 1;

	$flserver->fileset_mask_aggregate($aggr);

	my $aggr_used = 0;
	my $aggr_quota = 0;
	my $aggr_rw = 0;
	my $aggr_ro = 0;
	my $aggr_reads = 0;
	my $aggr_writes = 0;
	my $aggr_seconds = 0;

	while (1) {

	    my ($fileset, $status) = $flserver->fileset;

	    last if ($status == $flserver->status_endoflist);

	    $status and print "error enumerating filesets - $status\n" and exit;

	    my $ftserver_index = $fileset->ftserver_index($ftserver);

	    my ($quota, $used, $status) = $fileset->quota;

	    $aggr_quota += $quota;
	    $aggr_used += $used;

	    if ($fileset->exists($fileset->type_rw, $ftserver_index)) {

		my ($seconds, $reads, $writes, $status) = $fileset->usage();

		$aggr_rw++;
		$aggr_reads += $reads;
		$aggr_writes += $writes;
		$aggr_seconds += $seconds;

		my $rpd = ($seconds > 0) ? 24 * 60 * 60 * $reads / $seconds : 0;
		my $wpd = ($seconds > 0) ? 24 * 60 * 60 * $writes / $seconds : 0;

		printf("      %7d rpd %7d wpd %8s / %-8s (%5.2f%%)  %s\n",
		       $rpd, $wpd, fmt_size($used), fmt_size($quota), ($used/$quota)*100, $fileset->name) if $verbosity > 2;

		if ($fileset->exists($fileset->type_ro, $ftserver_index)) {

		    my ($seconds, $reads, $writes, $status) = $fileset->usage($ftserver_index, $fileset->type_ro);

		    $aggr_ro++;
		    $aggr_reads += $reads;
		    $aggr_seconds += $seconds;

		    my $rpd = ($seconds > 0) ? 24 * 60 * 60 * $reads / $seconds : 0;
		    my $wpd = ($seconds > 0) ? 24 * 60 * 60 * $writes / $seconds : 0;

		    printf("      %7d rpd %7d wpd                               %s\n",
			   $rpd, $wpd, $fileset->name . ".readonly") if $verbosity > 2;
		}
	    }
	    elsif ($fileset->exists($fileset->type_ro, $ftserver_index)) {

		my ($seconds, $reads, $writes, $status) = $fileset->usage($ftserver_index, $fileset->type_ro);

		$aggr_ro++;
		$aggr_reads += $reads;
		$aggr_seconds += $seconds;

		my $rpd = ($seconds > 0) ? 24 * 60 * 60 * $reads / $seconds : 0;
		my $wpd = ($seconds > 0) ? 24 * 60 * 60 * $writes / $seconds : 0;

		printf("      %7d rpd %7d wpd %8s / %-8s (%5.2f%%)  %s\n",
		       $rpd, $wpd, fmt_size($used), fmt_size($quota), ($used/$quota)*100, $fileset->name . ".readonly") if $verbosity > 2;
	    }
	}
	$ftserver_used += $aggr_used;
	$ftserver_quota += $aggr_quota;
	$ftserver_rw += $aggr_rw;
	$ftserver_ro += $aggr_ro;
	$ftserver_reads += $aggr_reads;
	$ftserver_writes += $aggr_writes;
	$ftserver_seconds += $aggr_seconds;

	next if $verbosity < 2;

	my $aggr_rpd = ($aggr_rw + $aggr_ro > 0 && $aggr_seconds > 0) ? 24 * 60 * 60 * $aggr_reads / ($aggr_seconds / ($aggr_rw + $aggr_ro)) : 0;
	my $aggr_wpd = ($aggr_rw + $aggr_ro > 0 && $aggr_seconds > 0) ? 24 * 60 * 60 * $aggr_writes / ($aggr_seconds / ($aggr_rw + $aggr_ro)) : 0;

	print "\n";
	printf("   Aggregate total:   %d rpd %d wpd on $aggr_rw RW, $aggr_ro RO filesets\n", $aggr_rpd, $aggr_wpd);
        printf("                         %s used  / %s size  (", fmt_size($aggr_used), fmt_size($aggr->size));
	printf("%5.2f%%)\n", ($aggr_used/$aggr->size)*100);
        printf("                         %s used  / %s quota (", fmt_size($aggr_used), fmt_size($aggr_quota));
	printf("%5.2f%%)\n", ($aggr_quota > 0) ? (($aggr_used/$aggr_quota)*100) : 0);
        printf("                         %s quota / %s size  (", fmt_size($aggr_quota), fmt_size($aggr->size));
	printf("%5.2f%%)\n", ($aggr_quota/$aggr->size)*100);
	print "\n";
    }

    $cell_aggrs += $ftserver_aggrs;
    $cell_size += $ftserver_size;
    $cell_used += $ftserver_used;
    $cell_quota += $ftserver_quota;
    $cell_rw += $ftserver_rw;
    $cell_ro += $ftserver_ro;
    $cell_reads += $ftserver_reads;
    $cell_writes += $ftserver_writes;
    $cell_seconds += $ftserver_seconds;

    next if $verbosity < 1;
    
    my $ftserver_rpd = ($ftserver_rw + $ftserver_ro > 0 && $ftserver_seconds > 0) ? 24 * 60 * 60 * $ftserver_reads /
	($ftserver_seconds / ($ftserver_rw + $ftserver_ro)) : 0;
    my $ftserver_wpd = ($ftserver_rw + $ftserver_ro > 0 && $ftserver_seconds > 0) ? 24 * 60 * 60 * $ftserver_writes /
	($ftserver_seconds / ($ftserver_rw + $ftserver_ro)) : 0;

    print "\n";
    printf("  Fileserver total:   %d rpd %d wpd on $ftserver_rw RW, $ftserver_ro RO filesets on $ftserver_aggrs aggregates\n", $ftserver_rpd, $ftserver_wpd);
    printf("                       %s used / %s size (", fmt_size($ftserver_used), fmt_size($ftserver_size));
    printf("%5.2f%%)\n", ($ftserver_used/$ftserver_size)*100);
    printf("                       %s used / %s quota (", fmt_size($ftserver_used), fmt_size($ftserver_quota));
    printf("%5.2f%%)\n", ($ftserver_quota > 0) ? (($ftserver_used/$ftserver_quota)*100) : 0);
    printf("                       %s quota / %s size (", fmt_size($ftserver_quota), fmt_size($ftserver_size));
    printf("%5.2f%%)\n", ($ftserver_quota/$ftserver_size)*100);
    print "\n";
}

print "\n";
print "Cell total:          $cell_rw RW, $cell_ro RO filesets, $cell_aggrs aggregates, $cell_ftservers fileservers\n";
printf("                     %d rpd %d wpd\n", $cell_reads / ($cell_seconds / ($cell_rw + $cell_ro)),
                                               $cell_writes / ($cell_seconds / ($cell_rw + $cell_ro)));
printf("                     %s used / %s size (", fmt_size($cell_used), fmt_size($cell_size));
printf("%5.2f%%)\n", ($cell_used/$cell_size)*100);
printf("                     %s used / %s quota (", fmt_size($cell_used), fmt_size($cell_quota));
printf("%5.2f%%)\n", ($cell_quota > 0) ? (($cell_used/$cell_quota)*100) : 0);
printf("                     %s quota / %s size (", fmt_size($cell_quota), fmt_size($cell_size));
printf("%5.2f%%)\n", ($cell_quota/$cell_size)*100);
print "\n";

exit;
	

sub fmt_size {
    my ($size) = @_;
    my $unit, $div;

    if ($size > 1048576) {
	$unit = "G";
	$div = 1048576;
    }
    elsif ($size > 1024) {
	$unit = "M";
	$div = 1024;
    }
    else {
	$unit = "K";
	$div = 1;
    }

    return (sprintf("%0.2f", $size/$div) . $unit);
}
    
