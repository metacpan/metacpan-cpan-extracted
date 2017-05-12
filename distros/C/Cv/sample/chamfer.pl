#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

sub help {
	die <<"----";
This program demonstrates Chamfer matching -- computing a distance between an
edge template and a query edge image.
Usage: .\/chamfer <image edge map> <template edge map>,
By default the inputs are logo_in_clutter.png logo.png
----
}

my $imgname = shift || dirname($0) . "/logo_in_clutter.png";
my $tplname = shift || dirname($0) . "/logo.png";
my $img = Cv->loadImageM($imgname, CV_LOAD_IMAGE_GRAYSCALE);
my $tpl = Cv->loadImageM($tplname, CV_LOAD_IMAGE_GRAYSCALE);
&help unless $img && $tpl;
my $cimg = $img->cvtColor(CV_GRAY2BGR);

# if the image and the template are not edge maps but normal grayscale
# images, you might want to uncomment the lines below to produce the
# maps. You can also run Sobel instead of Canny.
# $img = $img->canny(5, 50, 3);
# $tpl = $tpl->canny(5, 50, 3);

my $best = Cv->chamerMatching($img, $tpl, my $results, my $costs);
die "matching not found\n" unless $best >= 0;

my ($w, $h) = ($cimg->width, $cimg->height);
my $green = [0, 255, 0];
foreach my $pt (@{$results->[$best]}) {
    my ($x, $y) = @{$pt};
    next unless 0 <= $x && $x < $w && 0 <= $y && $y < $h;
    $cimg->set($y, $x, $green);
}

Cv->namedWindow("result", 0);
$cimg->show("result");
Cv->waitKey;

use Cv::Config;
use Inline C => Config => %Cv::Config::C;
use Inline C => << '----';
#include <opencv/cv.h>
#ifndef __cplusplus
#define __OPENCV_BACKGROUND_SEGM_HPP__
#define __OPENCV_VIDEOSURVEILLANCE_H__
#endif
#include <opencv/cvaux.h>

#ifdef __cplusplus
using namespace cv;
using namespace std;
#endif

MODULE = Cv	PACKAGE = Cv::Arr

int
cvChamerMatching(CvArr* img, CvArr* templ, results, costs, double templScale=1, int maxMatches = 20, double minMatchDistance = 1.0, int padX = 3, int padY = 3, int scales = 5, double minScale = 0.6, double maxScale = 1.6, double orientationWeight = 0.5, double truncate = 20)
ALIAS: Cv::cvChamerMatching = 1
PREINIT:
	vector<vector<Point> > results;
	vector<float> costs;
INIT:
	Mat _img = cv::cvarrToMat(img);
	Mat _templ = cv::cvarrToMat(templ);
CODE:
	RETVAL = chamerMatching(_img, _templ, results, costs, templScale, maxMatches, minMatchDistance, padX, padY, scales, minScale, maxScale, orientationWeight, truncate);
	AV* av_vv = newAV();
	for (int i = 0; i < results.size(); i++) {
		AV* av_v = newAV();
		for (int j = 0; j < results[i].size(); j++) {
			AV* av_pt = newAV();
			av_push(av_pt, newSViv(results[i][j].x));
			av_push(av_pt, newSViv(results[i][j].y));
			av_push(av_v, newRV_inc(sv_2mortal((SV*)av_pt)));
		}
		av_push(av_vv, newRV_inc(sv_2mortal((SV*)av_v)));
	}
	sv_setsv(ST(2), sv_2mortal(newRV_inc(sv_2mortal((SV*)av_vv))));
	AV* av_v = newAV();
	for (int i = 0; i < costs.size(); i++) {
		av_push(av_v, newSVnv(costs[i])); 
	}
	sv_setsv(ST(3), sv_2mortal(newRV_inc(sv_2mortal((SV*)av_v))));
OUTPUT:
	RETVAL

----
