#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $capture;
my $videoSource;
if (@ARGV == 0) {
    $capture = Cv::Capture->fromCAM(0);
    $videoSource = 0;
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $capture = Cv::Capture->fromCAM($ARGV[0]);
    $videoSource = $ARGV[0];
} else {
    $capture = Cv::Capture->fromFile($ARGV[0]);
    $videoSource = $ARGV[0];
}
$capture or die "can't create capture";

my $frame = $capture->queryFrame;
my $laplace = $frame->new(CV_16SC(CV_MAT_CN($frame->type)));

my $smoothType = CV_GAUSSIAN;
Cv->namedWindow("Laplacian", 0);
Cv->createTrackbar("Sigma", "Laplacian", my $sigma = 3, 15, sub {});

for (;;) {
	last unless my $frame = $capture->query->mirror(\0, 1);

	my $ksize = ($sigma * 5) | 1;
	my $colorlaplace = $frame->smooth(
		$frame->new, $smoothType, $ksize, $ksize, $sigma, $sigma);
	$colorlaplace->laplace($laplace, 5)
		->convertScaleAbs($colorlaplace, ($sigma + 1) * 0.25, 0)
		->show("Laplacian");

	my $c = Cv->waitKey(30);
	$c &= 0xffff if $c >= 0;
	if ($c == ord(' ')) {
		$smoothType =
			($smoothType == CV_GAUSSIAN) ? CV_BLUR :
			($smoothType == CV_BLUR) ? CV_MEDIAN : CV_GAUSSIAN;
	}
	last if $c == ord('q') || $c == ord('Q') || $c == 27;
}

exit;
