# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 39;
use Test::Number::Delta within => 1e-15;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

my ($cx, $cy) = (160, 120);

my @src = ([ $cx - 100, $cy - 100 ], [ $cx, $cy ], [ $cx - 100, $cy + 100 ]);
my @dst = ([ $cx + 100, $cy + 100 ], [ $cx, $cy ], [ $cx + 100, $cy - 100 ]);
my $map;

if (1) {
	if ($verbose) {
		my $img = Cv->createImage([2 * $cx, 2 * $cy], 8, 3);
		for (\@src, \@dst) {
			$img->zero;
			$img->polyLine([ $_ ], -1, [ 255, 255, 200 ], 1, CV_AA);
			$img->circle($_, 3, [ 200, 200, 255 ], -1) for @$_;
			$img->show;
			Cv->waitKey(1000);
		}
	}
	$map = Cv->GetAffineTransform(\@src, \@dst);
	delta_ok($map->getReal([0, 0]), -1);
	delta_ok($map->getReal([0, 1]), 0);
	delta_ok($map->getReal([0, 2]), 320);
	delta_ok($map->getReal([1, 0]), 0);
	delta_ok($map->getReal([1, 1]), -1);
	delta_ok($map->getReal([1, 2]), 240);
}


#  cvTransform(CvArr* src, CvArr* dst, CvMat* transmat, CvMat* shiftvec)

if (2) {
	my $src2 = Cv::Mat->new([], &Cv::CV_32FC2, @src);
	my $dst2 = $src2->Transform($map);
	my @dst2 = @$dst2;
	is($dst[0]->[0], $dst2[0]->[0]);
	is($dst[0]->[1], $dst2[0]->[1]);
	is($dst[1]->[0], $dst2[1]->[0]);
	is($dst[1]->[1], $dst2[1]->[1]);
	is($dst[2]->[0], $dst2[2]->[0]);
	is($dst[2]->[1], $dst2[2]->[1]);
}

if (3) {
	my $dst3 = Cv->Transform(\@src, $map);
	my @dst3 = @$dst3;
	is($dst[0]->[0], $dst3[0]->[0]);
	is($dst[0]->[1], $dst3[0]->[1]);
	is($dst[1]->[0], $dst3[1]->[0]);
	is($dst[1]->[1], $dst3[1]->[1]);
	is($dst[2]->[0], $dst3[2]->[0]);
	is($dst[2]->[1], $dst3[2]->[1]);
}

if (4) {
	Cv->Transform(\@src, my $dst4, $map);
	my @dst4 = @$dst4;
	is($dst[0]->[0], $dst4[0]->[0]);
	is($dst[0]->[1], $dst4[0]->[1]);
	is($dst[1]->[0], $dst4[1]->[0]);
	is($dst[1]->[1], $dst4[1]->[1]);
	is($dst[2]->[0], $dst4[2]->[0]);
	is($dst[2]->[1], $dst4[2]->[1]);
}

if (5) {
	my @dst5 = Cv->Transform(\@src, $map);
	is(scalar @dst5, 1);
	is($dst[0]->[0], $dst5[0]->[0]->[0]);
	is($dst[0]->[1], $dst5[0]->[0]->[1]);
	is($dst[1]->[0], $dst5[0]->[1]->[0]);
	is($dst[1]->[1], $dst5[0]->[1]->[1]);
	is($dst[2]->[0], $dst5[0]->[2]->[0]);
	is($dst[2]->[1], $dst5[0]->[2]->[1]);
}

if (6) {
	Cv::More->import(qw(cs));
	my @dst6 = Cv->Transform(\@src, $map);
	is(scalar @dst6, 3);
	is($dst[0]->[0], $dst6[0]->[0]);
	is($dst[0]->[1], $dst6[0]->[1]);
	is($dst[1]->[0], $dst6[1]->[0]);
	is($dst[1]->[1], $dst6[1]->[1]);
	is($dst[2]->[0], $dst6[2]->[0]);
	is($dst[2]->[1], $dst6[2]->[1]);
}
