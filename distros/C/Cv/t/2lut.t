# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 6;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

# ------------------------------------------------------------
#  void cvLUT(const CvArr* src, CvArr* dst, const CvArr* lut)
# ------------------------------------------------------------

sub gray2thermo {
	my @a = map { 255 * $_ / 31 } 0 .. 31;
	my @b = map { 127 * $_ / 31 } 0 .. 31;
	my @lut = (
		(map {[       $_, 0       , 0       ]} @a),
		(map {[ 255     ,       $_, 0       ]} @a),
		(map {[ 255 - $_, 255     , 0       ]} @a),
		(map {[ 0       , 255     ,      $_ ]} @a),
		(map {[ 0       , 255 - $_, 255     ]} @b),
		(map {[ 0       , 127 - $_, 255     ]} @b),
		(map {[       $_,       $_, 255     ]} @b),
		(map {[ 128 + $_, 128 + $_, 255     ]} @b),
		);
	wantarray? @lut : [@lut];
}

my @gray2thermo = &gray2thermo;

if (1) {
	my $gray2thermo = Cv::Mat->new([256], CV_8UC3);
	$gray2thermo->set([$_], $gray2thermo[$_]) for 0 .. $#gray2thermo;
	my $arr = Cv::Image->new([ (255 / sqrt(2)) x 2 ], CV_8UC1);
	for my $row (0 .. $arr->rows - 1) {
		for my $col (0 .. $arr->cols - 1) {
			$arr->set([$row, $col], [sqrt($row ** 2 + $col ** 2)]);
		}
	}
	my $thermo = $arr->LUT($arr->new(CV_8UC3), $gray2thermo);
	$gray2thermo->set([$_], cvScalarAll(0)) for 128 .. $#gray2thermo;
	my $thermo2 = $arr->LUT($arr->new(CV_8UC3), $gray2thermo);
	my $arr2 = $thermo2->cvtColor(CV_BGR2GRAY);
	if ($verbose) {
		for ($arr, $thermo, $thermo2, $arr2) {
			$_->show; Cv->waitKey(1000);
		}
	}
	my $count = $arr2->countNonZero;
	my $near_pi = 4 * $count / (128 * 128);
	my $e = $near_pi - 4 * atan2(1, 1);
	cmp_ok($e, '<', 0.1);
}

if (10) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC1);
	my $lut = Cv::Mat->new([256], CV_8UC1);
	lives_ok { $arr->LUT($lut) };
}

if (11) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC1);
	my $lut = Cv::Mat->new([256], CV_8UC3);
	lives_ok { $arr->LUT($lut) };
}

if (12) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	my $lut = Cv::Mat->new([256], CV_8UC1);
	throws_ok { $arr->LUT($lut) } qr/OpenCV Error:/;
}

if (13) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	my $lut = Cv::Mat->new([256], CV_8UC3);
	throws_ok { $arr->LUT($lut) } qr/OpenCV Error:/;
}
