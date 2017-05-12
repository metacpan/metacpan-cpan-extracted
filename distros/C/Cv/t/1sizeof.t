# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

ok(CV_SIZEOF('CvSeq'));
ok(CV_SIZEOF('CvContour'));
ok(CV_SIZEOF('CvPoint'));
ok(CV_SIZEOF('CvPoint3D32f'));
ok(CV_SIZEOF('CvSeq'));
ok(CV_SIZEOF('CvSet'));
throws_ok { CV_SIZEOF('abc') } qr/unknwon type abc in CV_SIZEOF at/;
