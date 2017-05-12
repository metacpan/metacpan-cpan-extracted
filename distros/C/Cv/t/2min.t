# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 18;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }
use List::Util qw(min);

# ------------------------------------------------------------
# void cvMin(const CvArr* src1, const CvArr* src2, CvArr* dst)
# void cvMinS(const CvArr* src, double value, CvArr* dst)
# ------------------------------------------------------------

my $src = Cv::Mat->new([ 3 ], CV_32SC1);

if (1) {
	my $src2 = $src->new;
	$src->set([0], [int rand 1000]);
	$src->set([1], [int rand 1000]);
	$src->set([2], [int rand 1000]);
	$src2->set([0], [int rand 1000]);
	$src2->set([1], [int rand 1000]);
	$src2->set([2], [int rand 1000]);
	my $dst = $src->min($src2);
	is($dst->getReal(0), min($src->getReal(0), $src2->getReal(0)));
	is($dst->getReal(1), min($src->getReal(1), $src2->getReal(1)));
	is($dst->getReal(2), min($src->getReal(2), $src2->getReal(2)));
}

if (2) {
	my $src2 = $src->new;
	$src->set([0], [int rand 1000]);
	$src->set([1], [int rand 1000]);
	$src->set([2], [int rand 1000]);
	$src2->set([0], [int rand 1000]);
	$src2->set([1], [int rand 1000]);
	$src2->set([2], [int rand 1000]);
	$src->min($src2, my $dst = $src->new);
	is($dst->getReal(0), min($src->getReal(0), $src2->getReal(0)));
	is($dst->getReal(1), min($src->getReal(1), $src2->getReal(1)));
	is($dst->getReal(2), min($src->getReal(2), $src2->getReal(2)));
}

if (3) {
	$src->set([0], [int rand 1000]);
	$src->set([1], [int rand 1000]);
	$src->set([2], [int rand 1000]);
	my $value = int rand 1000;
	my $dst = $src->min($value);
	is($dst->getReal(0), min($src->getReal(0), $value));
	is($dst->getReal(1), min($src->getReal(1), $value));
	is($dst->getReal(2), min($src->getReal(2), $value));
}

if (4) {
	$src->set([0], [int rand 1000]);
	$src->set([1], [int rand 1000]);
	$src->set([2], [int rand 1000]);
	my $value = int rand 1000;
	$src->min($value, my $dst = $src->new);
	is($dst->getReal(0), min($src->getReal(0), $value));
	is($dst->getReal(1), min($src->getReal(1), $value));
	is($dst->getReal(2), min($src->getReal(2), $value));
}

if (10) {
	throws_ok { $src->min(0, 0, 0) } qr/Usage: Cv::Arr::cvMinS\(src, value, dst\) at $0/;
	throws_ok { $src->min($src, 0, 0) } qr/Usage: Cv::Arr::cvMin\(src1, src2, dst\) at $0/;
}

if (11) {
	throws_ok { $src->min([1]) } qr/src2 is not of type CvArr \* in Cv::Arr::cvMin at $0/;
}

if (12) {
	throws_ok { $src->min(0, $src->new(CV_32FC1)) } qr/OpenCV Error:/;
}

if (13) {
	throws_ok { $src->min($src->new, $src->new(CV_32FC1)) } qr/OpenCV Error:/;
}
