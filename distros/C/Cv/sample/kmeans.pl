#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use List::Util qw(min max);

my $MAX_CLUSTERS = 5;
my @colorTab = (
    CV_RGB(255,   0,   0),
    CV_RGB(  0, 255,   0),
    CV_RGB(100, 100, 255),
    CV_RGB(255,   0, 255),
    CV_RGB(255, 255,   0),
	);

my $img = Cv::Image->new([500, 500], CV_8UC3);
my $rng = Cv->RNG(12345);

Cv->NamedWindow("clusters", 1);

while (1) {
	my $clusterCount = max($rng->RandInt % $MAX_CLUSTERS, 1);
	my $sampleCount = max($rng->RandInt % 1000, $MAX_CLUSTERS);
	my $points = Cv::Mat->new([$sampleCount, 1], CV_32FC2);
	my $clusters = Cv::Mat->new([$sampleCount, 1], CV_32SC1);

	# generate random sample from multigaussian distribution
	foreach my $k (0 .. $clusterCount - 1) {
		my ($startRow, $endRow) = (
			$sampleCount * ($k + 0) / $clusterCount,
			$k == $clusterCount - 1 ? $sampleCount :
			$sampleCount * ($k + 1) / $clusterCount,
			);
		my $pointChunk = $points->GetRows($startRow, $endRow);
		$rng->RandArr(
			$pointChunk, CV_RAND_NORMAL,
			cvScalar(map { $rng->RandInt % $_ } $img->width, $img->height),
			cvScalar(map { 0.1 * $_ } $img->width, $img->height),
			);
	}

	# shuffle samples
	foreach (0 .. $sampleCount / 2 - 1) {
		my $i = $rng->RandInt % $sampleCount;
		my $j = $rng->RandInt % $sampleCount;
		my $x = $points->get([$i, 0]);
		$points->set([$i, 0], $points->get([$j, 0]));
		$points->set([$j, 0], $x);
	}

	$points->KMeans2(
		$clusterCount, $clusters,
		cvTermCriteria(CV_TERMCRIT_EPS | CV_TERMCRIT_ITER, 10, 1.0),
		);

	$img->Zero;
	foreach (0 ..  $sampleCount - 1) {
		my $clusterIdx = ${$clusters->get([$_, 0])}[0];
		$img->Circle(
			$points->get([$_, 0]), 2, $colorTab[$clusterIdx],
			CV_FILLED, CV_AA, 0,
			);
	}
	$img->ShowImage("clusters");

	my $key = Cv->WaitKey(0);
	$key &= 0x7f if ($key >= 0);
	last if ($key == 27 || $key == ord('q') || $key == ord('Q')); # 'ESC'
}
