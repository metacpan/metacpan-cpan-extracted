# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
#  double cvInv(const CvArr* src, CvArr* dst, int method=CV_LU)
# ------------------------------------------------------------

if (1) {
	my $src = Cv::Mat->new([2, 2], CV_32FC1);
	$src->set([0, 0], [1]);
	$src->set([0, 1], [2]);
	$src->set([1, 0], [3]);
	$src->set([1, 1], [4]);
	my $det = $src->inv;
	ok($det);
}

if (2) {
	my $src = Cv::Mat->new([2, 2], CV_64FC1);
	my ($a, $b, $c, $d) = map { int rand 10 } 1 .. 4;
	$src->set([0, 0], [1]);
	$src->set([0, 1], [1]);
	$src->set([1, 0], [-1]);
	$src->set([1, 1], [-1]);
	my $det = $src->inv(my $inv = $src->new);
	ok($det == 0);
}

if (10) {
	my $src = Cv::Mat->new([2], CV_32FC1);
	throws_ok { $src->inv(1, 2) } qr/Usage: Cv::Arr::cvInv\(src, dst, method=CV_LU\) at $0/;
}

if (11) {
	my $src = Cv::Mat->new([2], CV_32FC1);
	throws_ok { $src->inv } qr/OpenCV Error:/;
}
