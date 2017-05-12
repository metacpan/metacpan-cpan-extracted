# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 3;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

if (1) {
	my $font = Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0, 0, 2, CV_AA);
	isa_ok($font, 'Cv::Font');
	my $img = Cv->CreateImage([320, 240], 8, 3);
	$img->zero;
	$img->putText("Hello, World", [ 30, 30 ], $font, cvScalarAll(255));
	if ($verbose) {
		$img->show("Font");
		Cv->waitKey(1000);
	}
}

if (10) {
	throws_ok { Cv->InitFont } qr/Usage: Cv::cvInitFont\(fontFace, hscale, vscale, shear=0, thickness=1, lineType=8\) at $0/;
}
