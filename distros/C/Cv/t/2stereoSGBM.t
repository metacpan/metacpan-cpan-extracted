# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 6;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

SKIP: {
	skip "no Cv->CreateStereoSGBM", 5 unless Cv->can('CreateStereoSGBM');
	if (1) {
		my @av;
		no warnings;
		local *{Cv::StereoSGBM::new} = sub { @av = @_ };
		Cv->CreateStereoSGBM(1, 2, 3);
		is($av[0], 'Cv::StereoSGBM');
		is($av[1], 1);
		is($av[2], 2);
		is($av[3], 3);
	}
	if (10) {
		throws_ok { Cv->CreateStereoSGBM(0) } qr/Usage: Cv::StereoSGBM::new\(CLASS\) at $0/;
	}
}

