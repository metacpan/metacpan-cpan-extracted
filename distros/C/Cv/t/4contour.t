# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('Cv') }

# use File::Basename;

my $verbose = Cv->hasGUI;

my $img = Cv::Mat->new([240, 320], CV_8UC1);
$img->zero;
my ($x0, $y0) = (100, 80);
$img->circle([$x0, $y0], 30, cvScalarAll(255), 10);
my ($x1, $y1) = ($x0 + 120, $y0);
$img->rectangle([$x1 - 30, $y1 - 30], [$x1 + 30, $y1 + 30],
				cvScalarAll(255), 10);
my ($x2, $y2) = ($x1 - 50, $y0 + 80);
$img->polyLine([ [ [$x2 - 30, $y2 + 30], [$x2 + 30, $y2 + 30],
				   [$x2, $y2 - 30], ], ], -1, cvScalarAll(255), 10);

if ($verbose) {
	$img->show;
	Cv->waitKey(1000);
}

my $storage = Cv->createMemStorage;

sub draw {
	my $cimg = shift;
	my $count = 0;
	for (my $contour = shift; $contour; $contour = $contour->h_next) {
		if (my $inner = $contour->v_next) {
			$count += &draw($cimg, $inner);
		}
		bless $contour, 'Cv::Seq::Point';
		my $color = [ map { 128 + int rand 128 } 1..3 ];
		$cimg->polyLine([scalar $contour->toArray], -1, $color, 3, CV_AA);
		$count++;
	}
	$count;
}

if (1) {
	my $cimg = $img->cvtColor(CV_GRAY2BGR);
	$img->findContours(
		$storage, my $contours,
		&CV_SIZEOF('CvContour'), CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
	my $count = &draw($cimg, $contours);
	is($count, 6);
	if ($verbose) {
		$cimg->show;
		Cv->waitKey(1000);
	}

	unlink("contours.xml");
    Cv->Save("contours.xml", $contours, \0, \0, [recursive => 1]);

    my $contours2 = Cv->Load("contours.xml", $storage);
	unlink("contours.xml");
    isa_ok($contours2, 'Cv::Seq');

	my $count2 = &draw($cimg, $contours2);
	is($count2, 6);
	if ($verbose) {
		$cimg->show;
		Cv->waitKey(1000);
	}
}

if (2) {
	my $cimg = $img->cvtColor(CV_GRAY2BGR);
	my $scanner = $img->startFindContours(
		$storage,
		&CV_SIZEOF('CvContour'), CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
	my $count = 0; $count++ while ($scanner->findNextContour());
	my $firstContour = $scanner->endFindContours();
	for (my $contour = $firstContour; $contour; $contour = $contour->h_next) {
		my $color = [ map { 128 + int rand 128 } 1..3 ];
		$cimg->drawContours($contour, $color, $color, 0, 3, CV_AA);
	}
	is($count, 6);
	if ($verbose) {
		$cimg->show;
		Cv->waitKey(1000);
	}
}
