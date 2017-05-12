# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 17;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
# int cvGetDims(const CvArr* arr, int* sizes=NULL)
# ------------------------------------------------------------

# (1) Cv::Arr::cvGetDims($arr, my @sizes)
# (2) Cv::Arr::GetDims($arr, my @sizes)
# (3) Cv::Arr::getDims($src, my @sizes);
# (4) my @sizes = Cv::Arr::getDims($src);
# (5) my $dims = Cv::Arr::getDims($src);
# (6) $src->GetDims(\ my @sizes);
# (7) $arr->GetDims;

my $src = Cv::Image->new([240, 320], CV_8UC3);

if (1) {
	Cv::Arr::cvGetDims($src, my @sizes);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (2) {
	Cv::Arr::GetDims($src, my @sizes);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (3) {
	Cv::Arr::getDims($src, my @sizes);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (4) {
	my @sizes = Cv::Arr::getDims($src);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (5) {
	my $dims = Cv::Arr::getDims($src);
	is($dims, 2);
}

if (6) {
	$src->GetDims(\ my @sizes);
	is(scalar @sizes, 2);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (7) {
	my @sizes = $src->GetDims;
	is(scalar @sizes, 2);
	is($sizes[0], $src->rows);
	is($sizes[1], $src->cols);
}

if (10) {
	throws_ok { Cv::Arr::GetDims(1) } qr/arr is not of type CvArr \* in Cv::Arr::cvGetDims at $0/;
}
