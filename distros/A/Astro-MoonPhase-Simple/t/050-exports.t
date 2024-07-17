#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.03';

use Test::More;
use Try::Tiny;

use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use Astro::MoonPhase::Simple;

#####
# check those subs exported by default
#####

for my $asub (qw/calculate_moon_phase/){
	try {
		no strict 'refs';
		$asub->()
	} catch {
		ok($_!~/Undefined subroutine/, "$asub : it is not exported as expected.") or BAIL_OUT
	}
}

for my $asub (qw/_event2str _parse_event/){
	try {
		no strict 'refs';
		$asub->()
	} catch {
		ok($_=~/Undefined subroutine/, "$asub : it is not exported as expected.") or BAIL_OUT
	}
}
done_testing;
