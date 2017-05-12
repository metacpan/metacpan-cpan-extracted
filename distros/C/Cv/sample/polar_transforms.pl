#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Data::Dumper;

my $USE_LINEARPOLAR = 0;

my $capture;
if (@ARGV == 0) {
    $capture = Cv::Capture->fromCAM(0);
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $capture = Cv::Capture->fromCAM($ARGV[0]);
} else {
    $capture = Cv::Capture->fromFile($ARGV[0]);
}
unless ($capture) {
    die <<"----";
Could not initialize capturing...
Usage: $0 <CAMERA_NUMBER>, or
       $0 <VIDEO_FILE>
----
;
}


sub help {
	print STDERR << "----"

This program illustrates Linear-Polar and Log-Polar image transforms
$ .\/polar_transforms [[camera number -- Default 0], [AVI path_filename]]

----
;
}

Cv->NamedWindow("Linear-Polar", 0);
Cv->NamedWindow("Log-Polar", 0);
Cv->NamedWindow("Recovered image", 0);

Cv->MoveWindow("Linear-Polar", 20, 20);
Cv->MoveWindow("Log-Polar", 700, 20);
Cv->MoveWindow("Recovered image", 20, 700);

my $log_polar_img;
my $lin_polar_img;
my $recovered_img;

while (my $frame = $capture->QueryFrame) {
    my $center = cvPoint2D32f($frame->width/2, $frame->height/2);

	unless ($log_polar_img) {
		$log_polar_img = Cv::Image->new(
			$frame->sizes, CV_MAKETYPE(CV_8U, $frame->nChannels),
			);
		$lin_polar_img = $log_polar_img->new;
		$recovered_img = $log_polar_img->new;
	}

	$frame->LogPolar(
		$log_polar_img, $center, 70, CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS,
		);
	$frame->LinearPolar(
		$lin_polar_img, $center, 70, CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS,
		);

	if ($0 =~ /log/) {
		$log_polar_img->LogPolar(
			$recovered_img,	$center, 70, CV_WARP_INVERSE_MAP + CV_INTER_LINEAR,
			);
	}
	if ($0 =~ /linear/) {
        $lin_polar_img->LinearPolar(
			$recovered_img, $center, 70,
			CV_WARP_INVERSE_MAP + CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS,
			);
	}

	$log_polar_img->ShowImage("Log-Polar");
	$lin_polar_img->ShowImage("Linear-Polar");
	$recovered_img->ShowImage("Recovered image");
    last if (Cv->WaitKey(10) >= 0);
}
