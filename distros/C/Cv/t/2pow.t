# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 8;
use Test::Number::Delta within => 1e-5;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
#  void cvPow(const CvArr* src, CvArr* dst, double power)
# ------------------------------------------------------------

my $src = Cv::Mat->new([3], CV_32FC1);
$src->set([0], [rand 3]);
$src->set([1], [rand 3]);
$src->set([2], [rand 3]);

if (1) {
	my $dst = $src->pow(2);
	delta_ok($dst->getReal(0), pow2($src->getReal(0)));
	delta_ok($dst->getReal(1), pow2($src->getReal(1)));
	delta_ok($dst->getReal(2), pow2($src->getReal(2)));
}

if (2) {
	$src->pow(my $dst = $src->new, 2);
	delta_ok($dst->getReal(0), pow2($src->getReal(0)));
	delta_ok($dst->getReal(1), pow2($src->getReal(1)));
	delta_ok($dst->getReal(2), pow2($src->getReal(2)));
}

if (10) {
	throws_ok { $src->pow() } qr/Usage: Cv::Arr::cvPow\(src, dst, power\) at $0/;
}

sub pow2 {
	my $x = shift;
	$x * $x;
}
