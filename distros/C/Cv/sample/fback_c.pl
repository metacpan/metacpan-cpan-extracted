#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

sub help {
	print << "----";
This program demonstrate dense Farneback optical flow.  It read from camera 0,
and shows how to use and display dense Franeback optical flow
Call:
\$ .\/fback_c
----
;
}

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

my $prevgray;
my $gray;
my $flow;
my $cflow;

help();

Cv->NamedWindow("flow", 1);
    
while (1) {
	my $firstFrame = !$gray;
	last unless my $frame = $capture->QueryFrame;
	unless ($gray) {
		$gray = Cv::Mat->new($frame->sizes, CV_8UC1);
		$prevgray = Cv::Mat->new($frame->sizes, CV_8UC1);
		$flow = Cv::Mat->new($gray->sizes, CV_32FC2);
		$cflow = Cv::Mat->new($gray->sizes, CV_8UC3);
	}
	$frame->CvtColor($gray, CV_BGR2GRAY);
	unless ($firstFrame) {
		Cv->CalcOpticalFlowFarneback(
			$prevgray, $gray, $flow, 0.5, 3, 15, 3, 5, 1.2, 0);
		$prevgray->CvtColor($cflow, CV_GRAY2BGR);
		drawOptFlowMap($flow, $cflow, 16, 1.5, CV_RGB(0, 255, 0));
		$cflow->ShowImage("flow");
	}
	last if(Cv->WaitKey(30) >= 0);
	($prevgray, $gray) = ($gray, $prevgray);
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

void drawOptFlowMap(const CvMat* flow, CvMat* cflowmap,
					int step, double scale, CvScalar color)
{
    int i, j;
    for (j = 0; j < cflowmap->rows; j += step) {
        for (i = 0; i < cflowmap->cols; i += step) {
            CvPoint2D32f pt = CV_MAT_ELEM(*flow, CvPoint2D32f, j, i);
            CvPoint pt0 = cvPoint(i, j);
			CvPoint pt1 = cvPoint(cvRound(i + pt.x), cvRound(j + pt.y));
            cvLine(cflowmap, pt0, pt1, color, 1, 8, 0);
            cvCircle(cflowmap, pt0, 2, color, -1, 8, 0);
        }
    }
}
----
