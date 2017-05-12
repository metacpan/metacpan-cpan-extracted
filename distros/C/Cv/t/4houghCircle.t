# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 9;
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
my $img = $src->cvtColor(CV_GRAY2RGB);

my $gray = $img->cvtColor(CV_BGR2GRAY)->smooth(CV_GAUSSIAN, 5, 5);
my $storage = Cv->createMemStorage;
my $circles = bless $gray->houghCircles(
	$storage, CV_HOUGH_GRADIENT, 1, 30, 100, 50), "Cv::Seq::Circle";
can_ok($circles, 'total');

for ($circles->toArray) {
	my $color = cvScalar(100, 100, 255);
	$img->circle($_->[0], 3, $color, 3, CV_AA);
	$img->circle($_->[0], $_->[1], $color, 3, CV_AA);
}
if ($circles->total > 0) {
	my $circle = $circles->getSeqElem(0);
	my ($center, $radius) = $circles->getSeqElem(0);
	is($circle->[0]->[0], $center->[0]);
	is($circle->[0]->[1], $center->[1]);
	is($circle->[1], $radius);
}

is($circles->total, 1);

$circles->push(my $x = [[10, 20], 30]);
my $y = $circles->pop();
is($x->[0]->[0], $y->[0]->[0]);
is($x->[0]->[1], $y->[0]->[1]);
is($x->[1], $y->[1]);

if ($verbose) {
	Cv->namedWindow("Circles", 1);
	$img->showImage("Circles");
	Cv->WaitKey(1000);
}
