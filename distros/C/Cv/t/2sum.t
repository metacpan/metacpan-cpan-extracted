# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $src = Cv::Mat->new([ 3, 3 ], CV_8UC4);
$src->fill([0, 1, 2, 3]);
my $dst = $src->sum;
is($dst->[0], 0 * 9);
is($dst->[1], 1 * 9);
is($dst->[2], 2 * 9);
is($dst->[3], 3 * 9);

if (10) {
	throws_ok { $src->fill } qr/Usage: Cv::Arr::cvFill\(arr, value, mask=NULL\) at $0/;
}

if (11) {
	throws_ok { $src->fill({}) } qr/value is not of type CvScalar in Cv::Arr::cvSet at $0/;
}
