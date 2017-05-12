# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 2;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

if (1) {
	my $img = Cv::Image->new([240, 320], CV_8UC3);
	my @pts = (
		[ [ 100, 100 ], [ 200, 100 ], [ 200, 200 ], [ 100, 200 ] ],
		[ [  90,  90 ], [ 210,  90 ], [ 210, 210 ], [  90, 210 ] ],
		);
	$img->polyLine(\@pts, 1, [ map { rand(255) } 1..3 ]);
	if ($verbose) {
		$img->show("polyLine");
		Cv->waitKey(1000);
	}
}

if (10) {
	my $img = Cv::Image->new([240, 320], CV_8UC3);
	throws_ok { $img->polyLine } qr/Usage: Cv::Arr::cvPolyLine\(img, pts, is_closed, color, thickness= 1, line_type= 8, shift= 0\) at $0/;
}
