#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $img = Cv->CreateMat(500, 500, CV_8UC3);
while (1) {
	my @points = map {
		[ map { $_ / 4 + rand $_ * 2/4 } $img->cols, $img->rows ]
	} 0 .. rand(99), 99 .. 100;
	$img->zero;
	$img->circle($_, 3, cvScalar(0, 0, 255), CV_FILLED, CV_AA) for @points;
	my $box = Cv->minAreaRect(@points);
	$img->polyLine([[Cv->boxPoints($box)]], -1, cvScalar(0, 255, 0), 1, CV_AA);
	# my ($center, $radius) = Cv->minEnclosingCircle(@points);
	my $center_radius = Cv->minEnclosingCircle(@points); # XXXXX
	my ($center, $radius) = @$center_radius;
	$img->circle($center, $radius, cvScalar(0, 255, 255), 1, CV_AA); 
	$img->show("rect & circle");
	my $key = Cv->waitKey;
	$key &= 0x7f if $key >= 0;
	last if $key == 27 || $key == ord('q') || $key eq ord('Q');
}
