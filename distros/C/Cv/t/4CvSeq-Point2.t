# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 3;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

my $src = Cv::Mat->new([240, 320], CV_8UC1);
$src->zero;
my ($x0, $y0) = (100, 80);
$src->circle([$x0, $y0], 30, cvScalarAll(255), 10);
my ($x1, $y1) = ($x0 + 120, $y0);
$src->rectangle([$x1 - 30, $y1 - 30], [$x1 + 30, $y1 + 30],
				cvScalarAll(255), 10);
my ($x2, $y2) = ($x1 - 50, $y0 + 80);
$src->polyLine([ [ [$x2 - 30, $y2 + 30], [$x2 + 30, $y2 + 30],
				   [$x2, $y2 - 30], ], ], -1, cvScalarAll(255), 10);

my $canny = $src->Canny(50, 200, 3);
my $color = $canny->CvtColor(CV_GRAY2BGR);

my $storage = Cv::MemStorage->new;
my $lines = bless $canny->HoughLines2(
	$storage, CV_HOUGH_PROBABILISTIC, 1, &CV_PI / 180, 30, 30, 10,
	), 'Cv::Seq::Point2';
$color->Line($_->[0], $_->[1], CV_RGB(255, 0, 0), 3, CV_AA, 0)
	for @$lines;

my @lines;
while (my $pt2 = $lines->shift) {
	push(@lines, $pt2);
}
is(scalar @$lines, 0);
$lines->push($_) for @lines;
is(scalar @$lines, scalar @lines);

if ($verbose) {
	$src->ShowImage("Source");
	$color->ShowImage("Hough");
	Cv->WaitKey(1000);
}
