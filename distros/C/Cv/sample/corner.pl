#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Time::HiRes qw(gettimeofday);
use List::Util qw(min max);

my $capture;
my $videoSource = shift || 0;
if ($videoSource =~ /^\d+$/) {
    $capture = Cv::Capture->fromCAM($videoSource);
} else {
    $capture = Cv::Capture->fromFile($videoSource);
}
$capture or die "can't capture from $videoSource";

Cv->namedWindow($videoSource, 0);
Cv->createTrackbar("blockSize", $videoSource, my $blockSize = 5, 20);
Cv->createTrackbar("Harris.k", $videoSource, my $k = 4, 10);

my $font = Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 0.4, 0.4, 0, 1, CV_AA);

sub lut_gray2thermo {
	my @a = map { 255 * $_ / 31 } 0 .. 31;
	my @b = map { 127 * $_ / 31 } 0 .. 31;
	[
	 (map {[       $_, 0       , 0       ]} @a),
	 (map {[ 255     ,       $_, 0       ]} @a),
	 (map {[ 255 - $_, 255     , 0       ]} @a),
	 (map {[ 0       , 255     ,      $_ ]} @a),
	 (map {[ 0       , 255 - $_, 255     ]} @b),
	 (map {[ 0       , 127 - $_, 255     ]} @b),
	 (map {[       $_,       $_, 255     ]} @b),
	 (map {[ 128 + $_, 128 + $_, 255     ]} @b),
	];
}

my $lut_gray2thermo = Cv::Mat->new([ ], CV_8UC3, &lut_gray2thermo);

sub ma (&) {
    my $subr = shift;
    my $t = gettimeofday;
    my $gray = &$subr;
	$gray->minMaxLoc(my $min, my $max);
    my $s = sprintf("%.1fms, %g .. %g", (gettimeofday - $t) * 1000, $min, $max);
	($min, $max) = (0, 255) unless ($max - $min);
	$gray = $gray->cvtScale($gray->new(CV_8UC1), 255 / ($max - $min), -$min);
	# $gray->cvtColor(CV_GRAY2BGR)
	$gray->LUT($gray->new(CV_8UC3), $lut_gray2thermo)
		->putText($s, [10 + 1, 20 + 1], $font, [  50,  50, 100 ])
		->putText($s, [10 + 0, 20 + 0], $font, [ 100, 100, 200 ]);
}

while (my $frame = $capture->queryFrame) {
    my $img = $frame->flip(\0, 1);
    $img->show($videoSource);
    if ($blockSize >= 1) {
		my $gray = $img->cvtColor(CV_BGR2GRAY);
		my $half = $gray->resize([map { $_ / 2 } @{$gray->sizes}]);

		ma {
			$half->Canny(100, 200)
				->resize($half->sizes);
		}
		->show('Canny');

		ma {
			$gray->CornerEigenValsAndVecs($blockSize, 7)
				->resize($half->sizes);
		}
		->show('CornerEigenValsAndVecs');

		ma {
			$half->CornerHarris($blockSize, 3, $k/100)
				->resize($half->sizes);
		}
		->show('CornerHarris');

		ma {
			$half->CornerMinEigenVal($blockSize, 3)
				->resize($half->sizes);
		}
		->show('CornerMinEigenVal');

    }
    my $c = Cv->waitKey(33);
    $c &= 0x7f if ($c >= 0);
    last if ($c == 27);
}
