#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('Data::Faker::Colour') }

sub valid{
	my $expected = shift;
	return unless $expected == @_;
	my $ret = 1;
	for my $colour (@_) {
		$ret &&= 0 <= $colour->[$_] && $colour->[$_] <= 255 for 0, 1, 2;
	}
	$ret
}

note 'These tests only check if the generated colours are valid. They don\'t check whether the colours have the requested hue, saturation or lightness';

my $f = Data::Faker::Colour->new;

ok valid (1, $f->colour), 'colour';
ok valid (5, $f->color(5)), 'color(5)';

ok valid (1, $f->colour_hsluv), 'colour_hsluv';
ok valid (200, $f->colour_hsluv(200, 10)), 'colour_hsluv(200, 10)';
ok valid (200, $f->colour_hsluv(200, -1, 10)), 'colour_hsluv(200, -1, 10)';
ok valid (200, $f->colour_hsluv(200, -1, -1, 10)), 'colour_hsluv(200, -1, -1, 10)';

ok valid (2000, $f->colour_hsluv(2000, -1, 100, 40)), 'colour_hsluv(2000, -1, 100, 40)';
