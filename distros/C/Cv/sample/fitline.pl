#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Cv::More qw(cs);

my $img = Cv::Image->new([250, 250], CV_8UC3)->fill(cvScalarAll(255));
$img->origin(1);
my @pts = ([  50,  50 ], [ 100, 120 ], [ 150, 150 ], [ 200, 150 ]);
# my $points = Cv::Mat->new([], &Cv::CV_32FC2, @pts);
# $points->fitLine(my $line); my ($vx, $vy, $x0, $y0) = @$line;
# my $line = Cv->fitLine(\@pts); my ($vx, $vy, $x0, $y0) = @$line;
my ($vx, $vy, $x0, $y0) = Cv->fitLine(\@pts);
$img->line((map { [ $_, $vy / $vx * ($_ - $x0) + $y0 ] } 20, 230),
		   cvScalarAll(200), 3, CV_AA);
$img->circle($_, 3, [200, 200, 255], -1, CV_AA) for @pts;
$img->show("FitLine");
Cv->waitKey;
