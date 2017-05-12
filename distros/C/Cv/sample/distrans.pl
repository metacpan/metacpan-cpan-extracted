#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Time::HiRes qw(gettimeofday);

my $filename = @ARGV > 0 ? shift : dirname($0).'/'."stuff.jpg";
my $gray = Cv->LoadImage($filename, CV_LOAD_IMAGE_GRAYSCALE)
	or die "Image was not loaded.\n";

print "Hot keys: \n",
	"\tESC - quit the program\n",
	"\tC - use C/Inf metric\n",
	"\tL1 - use L1 metric\n",
	"\tL2 - use L2 metric\n",
	"\t3 - use 3x3 mask\n",
	"\t5 - use 5x5 mask\n",
	"\t0 - use precise distance transform\n",
	"\tv - switch Voronoi diagram mode on/off\n",
	"\tSPACE - loop through all the modes\n";

my $dist = Cv::Image->new($gray->sizes, CV_32FC1);
my $dist8u1 = $gray->new;
my $dist8u2 = $gray->new;
my $dist8u = Cv::Image->new($gray->sizes, CV_8UC3);
my $dist32s = Cv::Image->new($gray->sizes, CV_32SC1);
my $labels = Cv::Image->new($gray->sizes, CV_32SC1);

my $build_voronoi = 0;
my $mask_size = CV_DIST_MASK_5;
my $dist_type = CV_DIST_L1;
my $edge_thresh = 100;

my $wndname = "Distance transform";
Cv->NamedWindow($wndname, 1);
Cv->CreateTrackbar(
	"Threshold", $wndname, $edge_thresh, 255, \&on_trackbar);

for (;;) {
	# Call to update the view
	&on_trackbar(100);
	
	my $c = Cv->WaitKey;
	$c &= 0x7f if ($c > 0);
	last if ($c == 27);

	my $key = chr($c);
	if ($key eq 'c' || $key eq 'C') {
		$dist_type = CV_DIST_C;
	} elsif ($key eq '1') {
		$dist_type = CV_DIST_L1;
	} elsif ($key eq '2') {
		$dist_type = CV_DIST_L2;
	} elsif ($key eq '3') {
		$mask_size = CV_DIST_MASK_3;
	} elsif ($key eq '5') {
		$mask_size = CV_DIST_MASK_5;
	} elsif ($key eq '0') {
		$mask_size = CV_DIST_MASK_PRECISE;
	} elsif ($key eq 'v') {
		$build_voronoi ^= 1;
	} elsif ($key eq ' ') {
		if ($build_voronoi) {
			$build_voronoi = 0;
			$mask_size = CV_DIST_MASK_3;
			$dist_type = CV_DIST_C;
		} elsif ($dist_type == CV_DIST_C) {
			$dist_type = CV_DIST_L1;
		} elsif ($dist_type == CV_DIST_L1) {
			$dist_type = CV_DIST_L2;
		} elsif ($mask_size == CV_DIST_MASK_3) {
			$mask_size = CV_DIST_MASK_5;
		} elsif ($mask_size == CV_DIST_MASK_5) {
			$mask_size = CV_DIST_MASK_PRECISE;
		} elsif ($mask_size == CV_DIST_MASK_PRECISE) {
			$build_voronoi = 1;
		}
	}
}

exit;    

# threshold trackbar callback
sub on_trackbar {
    my $edge = $gray->Threshold($edge_thresh, $edge_thresh, CV_THRESH_BINARY);
	if ($build_voronoi) {
		$edge->DistTransform($dist, CV_DIST_L2, CV_DIST_MASK_5, \0, $labels);
		&dovoronoi($labels, $dist, $dist8u);
	} else {
		$edge->DistTransform($dist, $dist_type, $mask_size);
        # begin "painting" the distance transform result
        $dist->ConvertScale(5000, 0)->Pow(0.5)
			->ConvertScale($dist32s, 1.0, 0.5);
        $dist32s->And(cvScalarAll(255), $dist32s)
			->ConvertScale($dist8u1, 1, 0);
		$dist32s->ConvertScale($dist32s, -1, 0)
			->Add(cvScalarAll(255), $dist32s)
			->ConvertScale($dist8u2, 1, 0);
        Cv->Merge([$dist8u1, $dist8u2, $dist8u2], $dist8u);
        # end "painting" the distance transform result
    }
    $dist8u->ShowImage($wndname);
}

BEGIN {
	die "$0: can't use Inline C.\n" if $^O eq 'cygwin';
}
use Cv::Config;
use Inline C => Config => %Cv::Config::C;
use Inline C => << '----';
#include <opencv/cv.h>
#ifndef __cplusplus
#define __OPENCV_BACKGROUND_SEGM_HPP__
#define __OPENCV_VIDEOSURVEILLANCE_H__
#endif
#include <opencv/cvaux.h>

void dovoronoi(IplImage* labels, IplImage* dist, IplImage* dist8u)
{
    static const uchar colors[][3] = {
        {   0,   0,   0 },
        { 255,   0,   0 },
        { 255, 128,   0 },
        { 255, 255,   0 },
        {   0, 255,   0 },
        {   0, 128, 255 },
        {   0, 255, 255 },
        {   0,   0, 255 },
        { 255,   0, 255 }
    };
	int i, j;
	for (i = 0; i < labels->height; i++) {
		int* ll = (int*)(labels->imageData + i*labels->widthStep);
		float* dd = (float*)(dist->imageData + i*dist->widthStep);
		uchar* d = (uchar*)(dist8u->imageData + i*dist8u->widthStep);
		for (j = 0; j < labels->width; j++) {
			int idx = ll[j] == 0 || dd[j] == 0 ? 0 : (ll[j] - 1)%8 + 1;
			int b = cvRound(colors[idx][0]);
			int g = cvRound(colors[idx][1]);
			int r = cvRound(colors[idx][2]);
			d[j*3 + 0] = (uchar)b;
			d[j*3 + 1] = (uchar)g;
			d[j*3 + 2] = (uchar)r;
		}
	}
}
----
