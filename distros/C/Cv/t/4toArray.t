# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 45;
use Test::Exception;
BEGIN { use_ok('Cv') }

for my $class (qw(Cv::Mat Cv::MatND)) {
	if (1) {
		my @pts = ([1, 2], [3, 4], [5, 6]);
		my $arr = $class->new([], CV_32FC2, @pts);
		ok($arr);
		is($arr->rows, 3);
		if ($class eq 'Cv::Mat') {
			is($arr->cols, 1);
		} else {
			is($arr->cols, 0);
		}
		my @list = $arr->toArray;
		is(scalar @list, 3);
		is_deeply([@list], [map {cvScalar(@$_)} @pts]);
		
		my @list2 = $arr->toArray(cvSlice(1, 1));
		is(scalar @list2, 1);
		is_deeply([@list2], [map {cvScalar(@$_)} $pts[1]]);
		
		$arr->toArray(\my @list3);
		is(scalar @list3, 3);
		is_deeply([@list3], [map {cvScalar(@$_)} @pts]);
		
		$arr->toArray(\my @list4, cvSlice(0, 1));
		is(scalar @list4, 2);
		is_deeply([@list4], [map {cvScalar(@$_)} @pts[0, 1]]);
	}

	if (2) {
		my @pts = ([1, 2], [3, 4], [5, 6]);
		my $arr = $class->new([], CV_32FC2, [@pts]);
		ok($arr);
		is($arr->rows, 1);
		is($arr->cols, 3);
		
		my @list = $arr->toArray;
		is(scalar @list, 3);
		is_deeply([@list], [map {cvScalar(@$_)} @pts]);
		
		my @list2 = $arr->toArray(cvSlice(1, 2));
		is(scalar @list2, 2);
		is_deeply([@list2], [map {cvScalar(@$_)} @pts[1, 2]]);
	}
	
	if (3) {
		my $arr = $class->new(
			[], CV_32FC1,
			[ 11, 12, 13 ],
			[ 21, 22, 23 ],
			[ 31, 32, 33 ],
			);
		ok($arr);
		is($arr->rows, 3);
		is($arr->cols, 3);
		throws_ok { my @list = @$arr } qr/can't convert 3x3 in Cv::Arr::ToArray at $0/;
	}
}
