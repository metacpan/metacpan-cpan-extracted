# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 5;
use Test::Number::Delta within => 1e-7;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
#  void cvMul(CvArr* src1, CvArr* src2, CvArr* dst, double scale=1)
# ------------------------------------------------------------

my $src1 = Cv::Mat->new([ 3 ], CV_32FC1);

if (1) {
	my $src2 = $src1->new;
	$src1->set([0], [rand]);
	$src1->set([1], [rand]);
	$src1->set([2], [rand]);
	$src2->set([0], [rand]);
	$src2->set([1], [rand]);
	$src2->set([2], [rand]);
	my $dst = $src1->mul($src2);
	delta_ok(
		[ $dst->getReal(0),
		  $dst->getReal(1),
		  $dst->getReal(2),
		],
		[ Mul($src1->getReal(0), $src2->getReal(0)),
		  Mul($src1->getReal(1), $src2->getReal(1)),
		  Mul($src1->getReal(2), $src2->getReal(2)),
		],
		);
}

if (2) {
	my $src2 = $src1->new;
	$src1->set([0], [rand]);
	$src1->set([1], [rand]);
	$src1->set([2], [rand]);
	$src2->set([0], [rand]);
	$src2->set([1], [rand]);
	$src2->set([2], [rand]);
	$src1->mul($src2, my $dst = $src1->new);
	delta_ok(
		[ $dst->getReal(0),
		  $dst->getReal(1),
		  $dst->getReal(2),
		],
		[ Mul($src1->getReal(0), $src2->getReal(0)),
		  Mul($src1->getReal(1), $src2->getReal(1)),
		  Mul($src1->getReal(2), $src2->getReal(2)),
		],
		);
}

if (10) {
	throws_ok { $src1->Mul(0, 0, 0, 0) } qr/Usage: Cv::Arr::cvMul\(src1, src2, dst, scale=1\) at $0/;
}

if (12) {
	throws_ok { $src1->Mul(\0) } qr/OpenCV Error:/;
}

sub Mul {
	my ($a, $b) = @_;
	$a * $b;
}
