# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 24;
use Test::Exception;
BEGIN { use_ok('Cv') }

for my $type (CV_8UC3, CV_16SC4, CV_32SC2, CV_32FC2, CV_64FC1) {
	my $cn = CV_MAT_CN($type);

	my $stor = Cv::MemStorage->new(8192);
	ok($stor->isa('Cv::MemStorage'));

	my $seq = Cv::Seq::Point->new($type, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	my $n = 10;
	my @pts = (map { [ map { int rand 256 } 1 .. $cn ] } 1 .. $n);
	$seq->Push(@pts);
	
	# seq to perl array
	my @pts2 = @$seq;
	is_deeply(\@pts2, \@pts);

	my $mat2 = Cv::Mat->new([$n, 1], $type);
	$mat2->set([], \@pts);

	# mat to perl array that always has 4 elements - XXXXX
	my @pts3 = @$mat2;
	splice(@$_, CV_MAT_CN($type)) for @pts3;
	is_deeply(\@pts3, \@pts);
}

if (1) {
	my $mat1 = Cv::Mat->new([ 240, 320 ], CV_8UC1);
	my $mat2 = $mat1->new;
	ok($mat1 != $mat2);
	ok($mat1 ne $mat2);
	throws_ok { $mat1++ } qr/Operation \"\+\+\": no method found, argument in overloaded package Cv::Mat at $0/;
}
