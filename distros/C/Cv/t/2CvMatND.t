# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 173;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $class = 'Cv::MatND';

# structure member: $obj->{structure_member}
if (1) {
	my $arr = $class->new(my $sizes = [240, 320], my $type = CV_8UC3);
	isa_ok($arr, $class);

	throws_ok { $arr->size } qr/OpenCV Error:/;

	throws_ok { $arr->origin } qr/can't call ${class}::origin at $0/;
}

# type: Cv::Mat->new([ $rows, $cols ], $type);
if (2) {
	my @type = (
		{ sizes => [2], type => CV_8UC1 },
		{ sizes => [2, 3], type => CV_8UC2 },
		{ sizes => [2, 3, 4], type => CV_8UC3 },
		{ sizes => [2, 3, 4, 5], type => CV_8UC4 },
		{ sizes => [2, 3, 4, 5, 6], type => CV_8SC1 },
		{ sizes => [2, 3, 4, 5, 6, 7], type => CV_8SC2 },
		{ sizes => [2, 3, 4, 5, 6, 7, 8], type => CV_8SC3 },
		{ sizes => [2, 3, 4, 5, 6, 7, 8, 9], type => CV_8SC4 },
		);
	for (@type) {
		my $arr = $class->new($_->{sizes}, $_->{type});
		isa_ok($arr, $class, "${class}->new");
		is($arr->type, $_->{type}, "${class}->type");
		is_deeply($arr->sizes, $_->{sizes}, "${class}->sizes");
		is(scalar $arr->getDims(\my @sizes), scalar @{$_->{sizes}},
		   "scalar ${class}->getDims");
		is_deeply(\@sizes, $_->{sizes}, "${class}->getDims(\@sizes)");
	}
	
	throws_ok { $class->new([-1, -1], CV_8UC3) } qr/OpenCV Error:/;
}

# has data
if (5) {
	my $rows = 8;
	my $cols = 8;
	my $cn = 4;
	my $step = $cols * $cn;
	my $data = chr(0) x ($rows * $step);
	substr($data, 0 + $_, 1) = chr($_ & 0xff) for 0 .. length($data) - 1;
	my $mat = Cv::MatND->new([ $rows, $cols ], CV_8UC($cn), $data);
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

# has data
if (0) {
	my $rows = 8;
	my $cols = 8;
	my $cn = 4;
	my $step = $cols * $cn;
	my $mat = Cv::MatND->new([ $rows, $cols ], CV_8UC($cn), undef);
}
