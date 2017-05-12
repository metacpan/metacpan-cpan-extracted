#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $imagename = shift || dirname($0) . "/lena.jpg";
my $img = Cv->loadImage($imagename);

# check if the image has been loaded properly
die "$0: Can not load image $imagename" unless $img;

my $rng = Cv->RNG(-1);
my $noise = $img->new(CV_32FC1);
$rng->randArr($noise, CV_RAND_NORMAL, cvScalarAll(0), cvScalarAll(20));
$noise->smooth($noise, CV_GAUSSIAN, 5, 5, 1, 1);

# convert image to YUV color space. The output image will be created
# automatically, and split the image into separate color planes
my ($y, $u, $v) = $img->cvtColor(CV_BGR2YCrCb)->split;
$y->acc($noise)->convert($y);
Cv->merge($y, $u, $v)->cvtColor(CV_YCrCb2BGR)->show($imagename);
Cv->waitKey();
