# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 15;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
# void cvAbsDiff(const CvArr* src1, const CvArr* src2, CvArr* dst)
# void cvAbsDiffS(const CvArr* src, CvScalar value, CvArr* dst)
# ------------------------------------------------------------

my $src = Cv::Mat->new([ 3, 3 ], CV_8UC3);

if (1) {
	my $src2 = $src->new;
	$src->fill([ 21, 22, 23, 24 ]);
	$src2->fill([ 11, 12, 13, 14 ]);
	$src->absDiff($src2, my $dst = $src->new);
	is(${$dst->get([0, 0])}[0], 10);
	is(${$dst->get([0, 0])}[1], 10);
	is(${$dst->get([0, 0])}[2], 10);
}

if (2) {
	my $src2 = $src->new;
	$src->fill([ 21, 22, 23, 24 ]);
	$src2->fill([ 11, 12, 13, 14 ]);
	my $dst = $src->absDiff($src2);
	is(${$dst->get([0, 0])}[0], 10);
	is(${$dst->get([0, 0])}[1], 10);
	is(${$dst->get([0, 0])}[2], 10);
}

if (3) {
	$src->fill([ 21, 22, 23, 24 ]);
	my $value = [ 11, 12, 13, 14 ];
	$src->absDiff($value, my $dst = $src->new);
	is(${$dst->get([0, 0])}[0], 10);
	is(${$dst->get([0, 0])}[1], 10);
	is(${$dst->get([0, 0])}[2], 10);
}

if (4) {
	$src->fill([ 21, 22, 23, 24 ]);
	my $value = [ 11, 12, 13, 14 ];
	my $dst = $src->absDiff($value);
	is(${$dst->get([0, 0])}[0], 10);
	is(${$dst->get([0, 0])}[1], 10);
	is(${$dst->get([0, 0])}[2], 10);
}


# broken new
if (10) {
	my $src2 = $src->new;
	$src->fill([ 21, 22, 23, 24 ]);
	$src2->fill([ 11, 12, 13, 14 ]);
	no warnings 'redefine';
	local *Cv::Mat::new = sub { undef };
	throws_ok { $src->absDiff($src2) } qr/dst is not of type CvArr \* in Cv::Arr::cvAbsDiff at $0/;
}

# OpenCV Error:
if (11) {
	my $src2 = $src->new;
	$src->fill([ 21, 22, 23, 24 ]);
	$src2->fill([ 11, 12, 13, 14 ]);
	throws_ok { $src->absDiff($src2, \0) } qr/OpenCV Error:/;
}
