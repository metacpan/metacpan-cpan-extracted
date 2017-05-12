#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my @colors = (
	[   0,   0, 255 ],
	[   0, 128, 255 ],
	[   0, 255, 255 ],
	[   0, 255,   0 ],
	[ 255, 128,   0 ],
	[ 255, 255,   0 ],
	[ 255,   0,   0 ],
	[ 255,   0, 255 ],
	[ 255, 255, 255 ],
	[ 196, 255, 255 ],
	[ 255, 255, 196 ],
	);

my @bcolors = (
	[   0,   0, 255 ],
	[   0, 128, 255 ],
	[   0, 255, 255 ],
	[   0, 255,   0 ],
	[ 255, 128,   0 ],
	[ 255, 255,   0 ],
	[ 255,   0,   0 ],
	[ 255,   0, 255 ],
	[ 255, 255, 255 ],
	);

my $path = shift || dirname($0) . "/puzzle.png";
my $img = Cv->loadImage($path, CV_LOAD_IMAGE_GRAYSCALE);
die "Usage: mser_sample <path_to_image>\n" unless $img;

my $rsp = Cv->loadImage($path, CV_LOAD_IMAGE_COLOR);
my $ellipses = $img->cvtColor(CV_GRAY2BGR);
my $hsv = $rsp->cvtColor(CV_BGR2YCrCb);

my $params = cvMSERParams();
# my $params = cvMSERParams(5, 60, cvRound(0.2 * $img->width * $img->height), 0.25, 0.2);

my $mask = $img->new(CV_8UC1)->fill(cvScalarAll(255))->rectangle(
	[ 0, 0 ], [ $img->width - 1, $img->height - 1 ], [ 0 ], 5,
	);

my $storage= Cv->createMemStorage;
my $t = Cv->getTickCount();
$hsv->extractMSER($mask, my $contours, $storage, $params);
# bless $contours, 'Cv::Seq::Seq';
$t = Cv->getTickCount() - $t;
printf "MSER extracted %d contours in %g ms.\n",
	$contours->total, $t/(Cv->getTickFrequency()*1000);

# draw mser with different color
foreach my $i (0 .. $contours->total - 1) {
	my $c = $bcolors[$i % @bcolors];
	my $r = bless $contours->get($i), 'Cv::Seq::Point';
	foreach my $j (0 .. $r->total - 1) {
		my $pt = $r->get($j);
		$rsp->circle($pt, 1, $c);
	}
}

# find ellipse ( it seems cvfitellipse2 have error or sth?
foreach my $i (0 .. $contours->total - 1) {
	my $r = $contours->get($i);
	my $box = $r->fitEllipse;
	$ellipses->ellipseBox($box, $colors[int rand @colors], 3);
}

# $rsp->SaveImage("rsp.png");

Cv->namedWindow("original", 0);
$img->showImage("original");

Cv->namedWindow("response", 0);
$rsp->showImage("response");

Cv->namedWindow("ellipses", 0);
$ellipses->showImage("ellipses");

Cv->waitKey(0);
