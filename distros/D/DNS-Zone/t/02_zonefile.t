#!/usr/local/bin/perl -w

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use DNS::Zone::File;

print "1..2\n";

my $zf = new DNS::Zone::File(
	'type' => 'default',
	'zone' => 'zonemaster.org',
	'file' => 't/data/zonemaster.org'
) or die "not ok 1\n";

print "ok 1\n";

$zf->parse() or die "not ok 2\n";

my $zone = $zf->zone();

print "ok 2\n" if(defined $zone && $zone);

