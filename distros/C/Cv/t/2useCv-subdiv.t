# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
use Cv -subdiv;

ok( __PACKAGE__->can('cvCreateImage')); # Cv
ok( __PACKAGE__->can('cvCreateHist'));  # Cv::Histogram
ok(!__PACKAGE__->can('cvCreateBGCodeBookModel'));  # Cv::BGCodeBookModel
ok( __PACKAGE__->can('cvCreateSubdivDelaunay2D')); # Cv::Subdiv2D
ok(!__PACKAGE__->can('cvFontQt'));				   # Cv::Qt
