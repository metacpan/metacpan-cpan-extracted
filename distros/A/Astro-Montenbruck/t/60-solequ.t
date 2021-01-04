#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Number::Delta within => 1e-5;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

BEGIN { use_ok( 'Astro::Montenbruck::SolEqu', qw/:all/ ) }

our $SOLSTICE_ERROR_MIN = 5;

subtest "Equinoxes/Solstices" => sub {

	my @cases = (
		# from 'Astronomical Formulae' by Jean Meeus, p.89
		{
			djd  => 29120.137,
			year => 1979,
			event => $SEPTEMBER_EQUINOX,
			angle => 180,
			title => 'Sept. equinox (Meeus, "Astronomical Formulae")'
		},
		# from 'Astronomical algorithms' by Jean Meeus, p.168
		{
			djd  => 22817.39,
			year => 1962,
			event => $JUNE_SOLSTICE,
			angle => 90,
			title => 'June solstice (Meeus, "Astronomical Algorithms")'
		},
		# from http://www.usno.navy.mil/USNO/astronomical-applications/data-services/earth-seasons
		{
			djd  => 36603.815972,
			year => 2000,
			event => $MARCH_EQUINOX,
			angle => 0,
			title => 'March equinox'
		},
		{
			djd  => 36696.575000,
			year => 2000,
			event => $JUNE_SOLSTICE,
			angle => 90,
			title => 'June solstice'
		},
		{
			djd  => 36790.227778,
			year => 2000,
			event => $SEPTEMBER_EQUINOX,
			angle => 180,
			title => 'September equinox'
		},
		{
			djd  => 36880.067361,
			year => 2000,
			event => $DECEMBER_SOLSTICE,
			angle => 270,
			title => 'December solstice'
		},
	);

	plan tests => scalar(@cases);
	my $err = $SOLSTICE_ERROR_MIN / 1440;
	for my $case(@cases) {
		my ($jd) = solequ($case->{year}, $case->{event});
        my $exp = $case->{djd} + 2415020;
		my $delta = abs($jd - $exp);
		cmp_ok($delta, '<', $err, "$case->{title} $case->{year}");
	}

}
