# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 2;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $mat = Cv::Mat->new([240, 320], CV_8UC1);
lives_ok { $mat->Cv::Image::new };
