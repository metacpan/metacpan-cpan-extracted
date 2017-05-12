#! /usr/local/bin/perl

use DCE::DFS;

if (scalar(@ARGV) != 1) {
    print "Usage: fileset.pl <name>\n";
    exit;
}

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

my ($fileset, $status) = $flserver->fileset_by_name($ARGV[0]); $status and
    print "Error creating fileset - $status\n" and exit;

print "RW " . ($fileset->exists($fileset->type_rw) ? "valid\n" : "invalid\n");
print "RO " . ($fileset->exists($fileset->type_ro) ? "valid\n" : "invalid\n");
print "BK " . ($fileset->exists($fileset->type_bk) ? "valid\n" : "invalid\n");

my ($ftserver, $status) = $fileset->ftserver; $status and
    print "Error creating ftserver - $status\n" and exit;

my ($aggr, $status) = $fileset->aggregate; $status and
    print "Error creating aggregate - $status\n" and exit;

my ($seconds, $reads, $writes, $status) = $fileset->usage; $status and
    print "Error obtaining usage - $status\n" and exit;

print "RW ftserver " . $ftserver->hostname . ", aggregate " . $aggr->name . ", usage: $reads reads $writes writes in $seconds seconds\n";

for (my $index = 0; $index < $fileset->ftserver_count; $index++) {
    my ($ftserver, $status) = $fileset->ftserver($index); $status and
	print "Error creating ftserver - $status\n" and exit;

    my ($aggr, $status) = $fileset->aggregate($index); $status and
	print "Error creating aggregate - $status\n" and exit;

    print "ftserver number " . $fileset->ftserver_index($ftserver) . ": " . $ftserver->hostname . ", aggregate " . $aggr->name . " [";
    print " RW" if $fileset->exists($fileset->type_rw, $index);
    print " RO" if $fileset->exists($fileset->type_ro, $index);
    print " BK" if $fileset->exists($fileset->type_bk, $index);
    print " ]\n";

    if ($fileset->exists($fileset->type_rw, $index)) {
	my ($seconds, $reads, $writes, $status) = $fileset->usage($index, $fileset->type_rw); $status and
	    print "Error obtaining usage - $status\n" and exit;

	print "  RW usage: $reads reads $writes writes in $seconds seconds\n";
    }
    if ($fileset->exists($fileset->type_ro, $index)) {
	my ($seconds, $reads, $writes, $status) = $fileset->usage($index, $fileset->type_ro); $status and
	    print "Error obtaining usage - $status\n" and exit;

	print "  RO usage: $reads reads $writes writes in $seconds seconds\n";
    }
    if ($fileset->exists($fileset->type_bk, $index)) {
	my ($seconds, $reads, $writes, $status) = $fileset->usage($index, $fileset->type_bk); $status and
	    print "Error obtaining usage - $status\n" and exit;

	print "  BK usage: $reads reads $writes writes in $seconds seconds\n";
    }
}

print "\n";

my ($quota, $used) = $fileset->quota;

print "quota: $quota, used: $used\n";
