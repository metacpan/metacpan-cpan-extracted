#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

# (1)load a specified file and convert it into grayscale image

my $imagename = shift || dirname($0) . "/trains.png";
my $src_img = Cv->loadImage($imagename);
die "can't load image: $imagename" unless ($src_img);

my $gray_img = $src_img->cvtColor(CV_BGR2GRAY);

# (2)apply a fixed-level threshold to each pixel

my $bin_img    = $gray_img->threshold(0, 255,
				      CV_THRESH_BINARY|CV_THRESH_OTSU);
my $bininv_img = $gray_img->threshold(0, 255,
				      CV_THRESH_BINARY_INV|CV_THRESH_OTSU);
my $trunc_img  = $gray_img->threshold(0, 255,
				      CV_THRESH_TRUNC|CV_THRESH_OTSU);
my $tozero_img = $gray_img->threshold(0, 255,
				      CV_THRESH_TOZERO|CV_THRESH_OTSU);
my $tozeroinv_img = $gray_img->threshold(0, 255,
					 CV_THRESH_TOZERO_INV|CV_THRESH_OTSU);

# (3)apply an adaptive threshold to a grayscale image

my $adaptive_img = $gray_img->adaptiveThreshold(
    255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY, 7, 8);

# (4)show source and destination images

$src_img->showImage("Source");
$bin_img->showImage("Binary");
$bininv_img->showImage("Binary Inv");
$trunc_img->showImage("Trunc");
$tozero_img->showImage("ToZero");
$tozeroinv_img->showImage("ToZero Inv");
$adaptive_img->showImage("Adaptive");
Cv->waitKey(0);

exit 0;
