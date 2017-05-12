# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 80;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $arr = Cv::Image->new([3, 4], CV_8UC3);
	isa_ok($arr, 'Cv::Image');
	$arr->fill([1, 2, 3]);
	my ($b, $g, $r) = $arr->Split;
	foreach my $row (0 .. $arr->rows - 1) {
		foreach my $col (0 .. $arr->cols - 1) {
			is(${$b->Get([$row, $col])}[0], 1);
			is(${$g->Get([$row, $col])}[0], 2);
			is(${$r->Get([$row, $col])}[0], 3);
		}
	}
}

if (2) {
	my $arr = Cv::Image->new([3, 4], CV_8UC3);
	isa_ok($arr, 'Cv::Image');
	$arr->fill([1, 2, 3]);
	my ($b, $g, $r) = map { $arr->new(CV_8UC1) } 1 .. $arr->channels;
	my $bgr = $arr->Split($b, $g, $r);
	is($bgr->[0], $b);
	is($bgr->[1], $g);
	is($bgr->[2], $r);
	foreach my $row (0 .. $arr->rows - 1) {
		foreach my $col (0 .. $arr->cols - 1) {
			is(${$b->Get([$row, $col])}[0], 1);
			is(${$g->Get([$row, $col])}[0], 2);
			is(${$r->Get([$row, $col])}[0], 3);
		}
	}
}

if (10) {
	my $mats = Cv::SparseMat->new([320, 240], CV_8UC4);
	throws_ok { $mats->split } qr/OpenCV Error:/;
}

SKIP: {
	skip "opencv-2.x", 1 unless cvVersion() >= 2.004;
	my $matn = Cv::MatND->new([320, 240], CV_8UC4);
	lives_ok { $matn->split };
}
