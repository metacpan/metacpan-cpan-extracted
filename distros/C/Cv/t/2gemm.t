# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 10;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $a = Cv->createMat(2, 2, CV_64FC1)
		->set([0, 0], [5])->set([0, 1], [6])
		->set([1, 0], [7])->set([1, 1], [8]);

	my $b = Cv->createMat(2, 2, CV_64FC1)
		->set((0, 0), [1])->set((0, 1), [2])
		->set((1, 0), [3])->set((1, 1), [4]);

	my $c = Cv->createMat(2, 2, CV_64FC1);

	$a->matMul($b, $c);

	is(${ $c->get([0, 0]) }[0],
	   ${ $a->get([0, 0]) }[0] * ${ $b->get([0, 0]) }[0] +
	   ${ $a->get([0, 1]) }[0] * ${ $b->get([1, 0]) }[0]);

	is(${ $c->get([0, 1]) }[0],
	   ${ $a->get([0, 0]) }[0] * ${ $b->get([0, 1]) }[0] +
	   ${ $a->get([0, 1]) }[0] * ${ $b->get([1, 1]) }[0]);

	is(${ $c->get([1, 0]) }[0],
	   ${ $a->get([1, 0]) }[0] * ${ $b->get([0, 0]) }[0] +
	   ${ $a->get([1, 1]) }[0] * ${ $b->get([1, 0]) }[0]);

	is(${ $c->get(1, 1) }[0],
	   ${ $a->get(1, 0) }[0] * ${ $b->get(0, 1) }[0] +
	   ${ $a->get(1, 1) }[0] * ${ $b->get(1, 1) }[0]);

	my $d = $a->matMul($b);
	is(${ $d->get([0, 0]) }[0],
	   ${ $a->get([0, 0]) }[0] * ${ $b->get([0, 0]) }[0] +
	   ${ $a->get([0, 1]) }[0] * ${ $b->get([1, 0]) }[0]);

	my $e = $a->matMulAdd($b, \0);
	is(${ $e->get([0, 0]) }[0],
	   ${ $a->get([0, 0]) }[0] * ${ $b->get([0, 0]) }[0] +
	   ${ $a->get([0, 1]) }[0] * ${ $b->get([1, 0]) }[0]);

	my $f = $a->GEMM($b, 1, \0, 1);
	is(${ $f->get([0, 0]) }[0],
	   ${ $a->get([0, 0]) }[0] * ${ $b->get([0, 0]) }[0] +
	   ${ $a->get([0, 1]) }[0] * ${ $b->get([1, 0]) }[0]);

}


if (10) {
	throws_ok { Cv::Arr::cvGEMM } qr/Usage: Cv::Arr::cvGEMM\(src1, src2, alpha, src3, beta, dst, tABC=0\) at $0/;
}

if (11) {
	my $a = Cv->createMat(2, 2, CV_64FC1);
	my $b = Cv->createMat(2, 3, CV_64FC1);
	throws_ok { $a->matMul($b) } qr/OpenCV Error:/;
}
