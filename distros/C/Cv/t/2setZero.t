# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

use File::Basename;
my $lena = dirname($0) . "/lena.jpg";
my $verbose = Cv->hasGUI;

# ------------------------------------------------------------
# void cvSetZero(CvArr* arr)
# void cvZero(CvArr* arr)
# ------------------------------------------------------------

# (11) Cv::Arr::cvSetZero(arr);
# (12) Cv::Arr::cvZero(arr);
# (13) Cv->SetZero(arr);
# (14) Cv->Zero(arr);
# (15) $arr->SetZero;
# (6) $arr->setZero;
# (17) $arr->Zero;
# (8) $arr->zero;

if (1) {
	my $arr = Cv->loadImage($lena, CV_LOAD_IMAGE_COLOR);
	isa_ok($arr, 'Cv::Image');
	my @channels = 0 .. $arr->nChannels - 1;

	if ($verbose) {
		$arr->show($lena);
		Cv->waitKey(1000);
	}

	if (11) {
		my $s1 = Cv::Arr::cvSetZero($arr->clone)->Sum;
		is($s1->[$_], 0) for @channels;
	}

	if (12) {
		my $s2 = Cv::Arr::cvZero($arr->clone)->Sum;
		is($s2->[$_], 0) for @channels;
	}

	my $zero = $arr->Zero;
	my $sum = cvScalarAll(0);
	foreach my $j (0 .. $arr->height - 1) {
		foreach my $i (0 .. $arr->width - 1) {
			my $x = $arr->Get($j, $i);
			$sum->[$_] += $x->[$_] for @channels;
		}
	}
	is($sum->[$_], 0) for @channels;
}

if (10) {
	my $arr = Cv->createMat(240, 320, CV_8UC3);
	throws_ok { $arr->setZero({}) } qr/Usage: Cv::Arr::cvSetZero\(arr\) at $0/;
}
