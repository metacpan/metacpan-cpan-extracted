# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use Test::More;
use Test::Exception;
BEGIN {
	plan skip_all => "Inline::C required"
		unless eval "use Inline; 1";
	plan tests => 6;
}

BEGIN {
	use_ok('Cv', -nomore);
}
use File::Basename;
my $lena = dirname($0) . "/lena.jpg";
my $verbose = Cv->hasGUI;

my $img1 = myload($lena);
my $sum1 = $img1->Sum;
my $img2 = Cv->LoadImage($lena);
my $sum2 = $img2->Sum;
is($sum1->[$_], $sum2->[$_], "ch#$_") for 0 .. $img1->channels - 1;
if ($verbose) {
	$img1->show('Inline C');
	Cv->waitKey(1000);
}

throws_ok { myload() } qr/Usage: main::myload\(name\)/;

BEGIN {
	use_ok('Cv::Config');
}
use Inline C => Config => %Cv::Config::C;
use Inline C => << '----';
#include <opencv/cv.h>
#include <opencv/highgui.h>
#ifndef __cplusplus
#define __OPENCV_BACKGROUND_SEGM_HPP__
#define __OPENCV_VIDEOSURVEILLANCE_H__
#endif
#include <opencv/cvaux.h>
IplImage* myload(const char* name)
{
	return cvLoadImage(name, CV_LOAD_IMAGE_COLOR);
}
----
