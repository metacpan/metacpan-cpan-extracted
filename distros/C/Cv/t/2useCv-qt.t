# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More;
eval "use Cv -qt";
plan skip_all => "Cv::Qt required for testing" if $@;
plan tests => 5;
ok( __PACKAGE__->can('cvCreateImage')); # Cv
ok( __PACKAGE__->can('cvCreateHist'));  # Cv::Histogram
ok(!__PACKAGE__->can('cvCreateBGCodeBookModel'));  # Cv::BGCodeBookModel
ok(!__PACKAGE__->can('cvCreateSubdivDelaunay2D')); # Cv::Subdiv2D
ok( __PACKAGE__->can('cvFontQt'));				   # Cv::Qt
