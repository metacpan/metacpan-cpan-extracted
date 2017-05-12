# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC1);
	my $arr2 = $arr->cvtScale(1, 0);
	is($arr2->type, $arr->type);
}

if (2) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	my $arr2 = $arr->cvtScale($arr->new(CV_32FC3), 1, 0);
	is($arr2->type, CV_32FC3);
}

if (3) {
	my $src = Cv::Mat->new([ 3 ], CV_32SC1);
	$src->set([0], [int rand 1000]);
	$src->set([1], [int rand 1000]);
	$src->set([2], [int rand 1000]);
	my $dst = $src->cvtScale(my $scale = 2, my $shift = 3);
	is($dst->getReal(0), CvtScale($src->getReal(0), $scale, $shift));
	is($dst->getReal(1), CvtScale($src->getReal(1), $scale, $shift));
	is($dst->getReal(2), CvtScale($src->getReal(2), $scale, $shift));
}

sub CvtScale {
	my ($x, $scale, $shift) = @_;
	$x * $scale + $shift;
}

if (10) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	throws_ok { $arr->cvtScale(1, 0, 1) } qr/Usage: Cv::Arr::cvConvertScale\(src, dst, scale=1, shift=0\) at $0/;
}

if (11) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	throws_ok { $arr->cvtScale($arr->new([120, 160])) } qr/OpenCV Error:/;
}
