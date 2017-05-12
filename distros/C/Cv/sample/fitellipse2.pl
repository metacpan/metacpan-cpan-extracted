#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $img = Cv::Image->new([250, 250], CV_8UC3)->fill(cvScalarAll(255));
$img->origin(1);
my @pts = (map { [ map { $_ / 4 + rand $_ / 2 } @{$img->size} ] } 1 .. 20);
$img->circle($_, 3, &color, 1, CV_AA) for @pts;
my $box = Cv->fitEllipse2(\@pts);
$img->polyLine([[Cv->boxPoints($box)]], -1, &color, 1, CV_AA);
$img->ellipseBox($box, &color, 1, CV_AA);
$img->show("FitEllipse2");
Cv->waitKey;

sub color { [ map { rand 255 } 1 .. 3 ] }
