# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

use File::Basename;
my $lena = dirname($0) . "/lena.jpg";
my $verbose = Cv->hasGUI;
my $window = $0;

my $image = Cv->loadImage($lena, CV_LOAD_IMAGE_GRAYSCALE);
isa_ok($image, 'Cv::Image');

my $thresh = 100;
my $bin1 = $image->Threshold(my $thresh1 = $thresh, 255, CV_THRESH_BINARY);
isa_ok($bin1, 'Cv::Image');
is($thresh1, $thresh);
if ($verbose) {
	$bin1->show($window);
	Cv->WaitKey(1000);
}

my $bin2 = $image->Threshold(my $thresh2 = $thresh, 255, CV_THRESH_OTSU);
isa_ok($bin2, 'Cv::Image');
isnt($thresh2, $thresh);
if ($verbose) {
	$bin2->show($window);
	Cv->WaitKey(1000);
}

if (10) {
	throws_ok { $image->Threshold } qr/Usage: Cv::Arr::cvThreshold\(src, dst, threshold, maxValue, thresholdType\) at $0/;
}
