#!/usr/bin/env perl

use strict;
use warnings;

use File::Object;
use IO::Barf qw(barf);
use Perl6::Slurp;

if (@ARGV < 1) {
	print STDERR "Usage: $0 cycles state_file\n";
	exit 1;
}
my $cycles = $ARGV[0];
my $state_file = $ARGV[1] || File::Object->new->file('state')->s;

my $state = 0;
if (-r $state_file) {
	$state = slurp($state_file);
}

$state++;
if ($state >= $cycles) {
	unlink $state_file;
} else {
	barf($state_file, $state);
}
