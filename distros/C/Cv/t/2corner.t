# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

my $arr = Cv::Mat->new([240, 320], CV_8UC1)->zero;

my @x;
for (0 .. int rand 10) {
	my $x = rand $arr->height;
	$arr->line([ $x, 0 ], [ $x, $arr->height - 1 ], cvScalarAll(64 + rand 192));
	push(@x, $x);
}

my @y;
for (0 .. int rand 10) {
	my $y = rand $arr->height;
	$arr->line([ 0, $y ], [ $arr->width - 1, $y ], cvScalarAll(64 + rand 192));
	push(@y, $y);
}

my $mask = $arr->new->zero;
for my $x (@x) {
	for my $y (@y) {
		$mask->circle([$x, $y], 5, cvScalarAll(255), -1, CV_AA);
	}
}

if ($verbose) {
	$arr->show;
	Cv->waitKey(100);
}


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
my $gray2thermo = Cv::Mat->new([256], CV_8UC3);
$gray2thermo->set([$_], $gray2thermo[$_]) for 0 .. $#gray2thermo;

my $blockSize = 3;

if (1) {
	my $corner = $arr->CornerEigenValsAndVecs($blockSize, 7)
		->resize($arr->sizes);
	$corner->minMaxLoc(my $min, my $max);
	my $gray = $corner->cvtScale(
		$corner->new(CV_8UC1), 255 / ($max - $min), -$min);
	my $thermo = $gray->LUT($gray->new(CV_8UC3), $gray2thermo);
	for my $x (@x) {
		for my $y (@y) {
			$thermo->circle([$x, $y], 5, CV_RGB(255, 100, 100), 1, CV_AA);
		}
	}
	if ($verbose) {
		$thermo->show('CornerEigenValsAndVecs');
		Cv->waitKey(100);
	}
}

if (2) {
	my $corner = $arr->CornerHarris($blockSize, 3, 0.04)
		->resize($arr->sizes);
	$corner->minMaxLoc(my $min, my $max);
	my $gray = $corner->cvtScale(
		$corner->new(CV_8UC1), 255 / ($max - $min), -$min);
	my $gray1 = $gray->copy($gray->new->zero, $mask);
	my $gray2 = $gray->copy($gray->new->zero, $mask->not);
	$gray1->avgSdv(my $mean1, my $stdDev1);
	$gray2->avgSdv(my $mean2, my $stdDev2);
	cmp_ok($mean1->[0], '>', 0);
	cmp_ok($stdDev1->[0], '>', 0);
	cmp_ok($mean2->[0], '==', 0);
	cmp_ok($stdDev2->[0], '==', 0);
	my $thermo = $gray->LUT($gray->new(CV_8UC3), $gray2thermo);
	for my $x (@x) {
		for my $y (@y) {
			$thermo->circle([$x, $y], 5, CV_RGB(255, 100, 100), 1, CV_AA);
		}
	}
	if ($verbose) {
		$thermo->show('CornerHarris');
		Cv->waitKey(100);
	}
}

if (3) {
	my $corner = $arr->CornerMinEigenVal($blockSize, 3)
		->resize($arr->sizes);
	$corner->minMaxLoc(my $min, my $max);
	my $gray = $corner->cvtScale(
		$corner->new(CV_8UC1), 255 / ($max - $min), -$min);
	my $gray1 = $gray->copy($gray->new->zero, $mask);
	my $gray2 = $gray->copy($gray->new->zero, $mask->not);
	$gray1->avgSdv(my $mean1, my $stdDev1);
	$gray2->avgSdv(my $mean2, my $stdDev2);
	cmp_ok($mean1->[0], '>', 0);
	cmp_ok($stdDev1->[0], '>', 0);
	cmp_ok($mean2->[0], '==', 0);
	cmp_ok($stdDev2->[0], '==', 0);
	my $thermo = $gray->LUT($gray->new(CV_8UC3), $gray2thermo);
	for my $x (@x) {
		for my $y (@y) {
			$thermo->circle([$x, $y], 5, CV_RGB(255, 100, 100), 1, CV_AA);
		}
	}
	if ($verbose) {
		$thermo->show('CornerMinEigenVal');
		Cv->waitKey(100);
	}
}

if ($verbose) {
	Cv->waitKey(1000);
}


if (10) {
	throws_ok { $arr->CornerEigenValsAndVecs } qr/Usage: Cv::Arr::cvCornerEigenValsAndVecs\(image, eigenvv, blockSize, aperture_size=3\) at $0/;

	throws_ok { $arr->CornerHarris } qr/Usage: Cv::Arr::cvCornerHarris\(image, harris_dst, blockSize, aperture_size=3, k=0\.04\) at $0/;

	throws_ok { $arr->CornerMinEigenVal } qr/Usage: Cv::Arr::cvCornerMinEigenVal\(image, eigenval, blockSize, aperture_size=3\) at $0/;
}
