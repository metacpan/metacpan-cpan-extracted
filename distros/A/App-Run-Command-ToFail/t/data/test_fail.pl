#!/usr/bin/env perl

use strict;
use warnings;

use File::Object;
use IO::Barf qw(barf);
use Perl6::Slurp;

if (@ARGV < 2) {
	print STDERR "Usage: $0 cycles cycle_to_fail\n";
	exit 1;
}
my $cycles = $ARGV[0];
my $cycle_to_fail = $ARGV[1];

my $state_file = File::Object->new->file('state')->s;
my $state = 0;
if (-r $state_file) {
	$state = slurp($state_file);
}

$state++;
if ($cycle_to_fail == $state) {
	print STDERR "Error.\n";
	unlink $state_file;
	exit 1;
}

if ($state >= $cycles) {
	unlink $state_file;
} else {
	barf($state_file, $state);
}
