# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 11;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }
use List::Util qw(min);

if (1) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC1);
	my $arr2 = $arr->cvtScaleAbs(1, 0);
	is($arr2->type, $arr->type);
}

if (2) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	throws_ok { $arr->cvtScaleAbs($arr->new(CV_32FC3), 1, 0) } qr/OpenCV Error:/;
}

if (3) {
	my $src = Cv::Mat->new([ 3 ], CV_32SC1);
	$src->set([0], [  int rand 1000]);
	$src->set([1], [- int rand  100]);
	$src->set([2], [- int rand 1000]);
	my $dst = $src->cvtScaleAbs(my $scale = 2, my $shift = 3);
	is($dst->getReal(0), CvtScaleAbs($src->getReal(0), $scale, $shift));
	is($dst->getReal(1), CvtScaleAbs($src->getReal(1), $scale, $shift));
	is($dst->getReal(2), CvtScaleAbs($src->getReal(2), $scale, $shift));
}

if (4) {
	my $src = Cv::Mat->new([ 3 ], CV_8SC1);
	$src->set([0], [  int rand 10]);
	$src->set([1], [- int rand 10]);
	$src->set([2], [- int rand 10]);
	my $dst = $src->cvtScaleAbs(my $scale = 2, my $shift = 3);
	is($dst->getReal(0), CvtScaleAbs($src->getReal(0), $scale, $shift));

  SKIP: {
	  skip "OpenCV-1.1", 2 unless cvVersion() >= 2.0;
	  is($dst->getReal(1), CvtScaleAbs($src->getReal(1), $scale, $shift));
	  is($dst->getReal(2), CvtScaleAbs($src->getReal(2), $scale, $shift));
	}
}

sub CvtScaleAbs {
	my ($x, $scale, $shift) = @_;
	min(abs($x * $scale + $shift), 255)
}

if (10) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	throws_ok { $arr->cvtScaleAbs(1, 0, 1) } qr/Usage: Cv::Arr::cvConvertScaleAbs\(src, dst, scale=1, shift=0\) at $0/;
}

if (11) {
	my $arr = Cv::Mat->new([240, 320], CV_8UC3);
	throws_ok { $arr->cvtScaleAbs($arr->new([120, 160])) } qr/OpenCV Error:/;
}
