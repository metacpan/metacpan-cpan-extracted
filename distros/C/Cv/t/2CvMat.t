# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 438;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $class = 'Cv::Mat';

# type: ${class}->new([ $rows, $cols ], $type);
if (2) {
	throws_ok { ${class}->new([-1, -1], CV_8UC3) } qr/OpenCV Error:/;
}

# has data (using Cv::More)
if (5) {
	my $rows = 8;
	my $cols = 8;
	my $cn = 4;
	my $step = $cols * $cn;
	my $data = chr(0) x ($rows * $step);
	substr($data, 0 + $_, 1) = chr($_ & 0xff) for 0 .. length($data) - 1;
	my $mat = ${class}->new([ $rows, $cols ], CV_8UC($cn), $data);
	for my $i (0 .. $rows - 1) {
		for my $j (0 .. $cols - 1) {
			my $k = (($i * $cols  + $j) * $cn) & 0xff;
			my @x = ($k .. $k + ($cn - 1));
			my $x = $mat->get([$i, $j]);
			is_deeply($x, \@x);
			my @y = map { $_ ^ 0xff } @x;
			$mat->set([$i, $j], \@y);
			my $y = $mat->get([$i, $j]);
			is_deeply($y, \@y);
		}
	}
}

# has data #2
if (6) {
	my $sizes = [8, 8];
	my $type = CV_8UC(4);
	my $step = $sizes->[1] * CV_MAT_CN($type);
	my @data = map { int rand 256 } 1 .. $sizes->[0] * $step;
	my $mat = ${class}->new($sizes, $type, join('', map { chr $_ } @data));
	for my $i (0 .. $mat->rows - 1) {
		for my $j (0 .. $mat->cols - 1) {
			for my $k (0 .. CV_MAT_CN($mat->type) - 1) {
				is($mat->get([$i, $j])->[$k],
				   $data[($i * $mat->cols + $j) * CV_MAT_CN($mat->type) + $k]);
			}
		}
	}
}

# has data #3
if (7) {
	my $data = pack("c*", ord('a') .. ord('z'));
	my $arr = ${class}->new([length($data)], CV_8UC1, $data);
	for my $i (0 .. length($data) - 1) {
		is($arr->get([$i])->[0], $i + ord('a'));
		is($arr->getReal([$i]), $i + ord('a'));
	}
}
