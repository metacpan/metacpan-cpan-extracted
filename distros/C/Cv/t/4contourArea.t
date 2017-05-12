# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 3;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

if (1) {
	my $img = Cv::Image->new([300, 300], CV_8UC3);
	my @pts = ([100, 100], [100, 200], [200, 200], [200, 100]);
	$img->polyLine([\@pts], -1, [ 100, 255, 255], 1, CV_AA);
	$img->circle($_, 3, [100, 255, 100], -1, CV_AA) for @pts;
	my $s = Cv->contourArea(\@pts);
	is(abs($s), 10000);
	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

if (2) {
	my @pts = ([100, 100], [100, 200], [200, 200], [200, 100]);
	my ($s) = Cv->contourArea(\@pts);
	is(abs($s), 10000);
}
