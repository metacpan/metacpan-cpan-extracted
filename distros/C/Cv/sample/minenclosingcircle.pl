#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Cv::More qw(cs);

my $img = Cv::Image->new([250, 250], CV_8UC3)->fill(cvScalarAll(255));
$img->origin(1);
my @pts = (map { [ map { $_ / 4 + rand $_ / 2 } @{$img->size} ] } 1 .. 20);
$img->circle($_, 3, &color, 1, CV_AA) for @pts;
my $rectangle1 = Cv->minAreaRect2(\@pts);
my ($x, $y, $w, $h) = Cv->boundingRect(\@pts);
my $rectangle2 = [ [ $x + $w / 2, $y + $h / 2 ], [ $w, $h ], 0 ];
my $ellipse = Cv->fitEllipse2(\@pts);
my ($center, $radius) = Cv->minEnclosingCircle(\@pts);
my $circle = [ $center, [ ($radius * 2) x 2 ], 0 ];
for (
	[ $rectangle1, [ 200, 100, 100 ] ],
	[ $rectangle2, [ 100, 200, 200 ] ],
	[ $ellipse,    [ 100, 100, 100 ] ],
	[ $circle,     [ 100, 100, 255 ] ],
	) {
	$img->polyLine([[Cv->boxPoints($_->[0])]], -1, $_->[1], 1, CV_AA);
	$img->ellipseBox($_->[0], $_->[1], 1, CV_AA);
}
$img->show("MinEnclosingCircle");
Cv->waitKey;

sub color { [ map { rand 255 } 1 .. 3 ] }
