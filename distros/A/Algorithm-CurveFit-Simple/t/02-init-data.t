#!/bin/env perl
use strict;
use warnings;
use Test::Most;
use JSON::PP;

use lib "./lib";
use Algorithm::CurveFit::Simple;

my ($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(); };
is $@, "must provide at least xydata or both xdata and ydata\n", "exception thrown for no parameters";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1, 2, 3]); };
is $@, "must provide at least xydata or both xdata and ydata\n", "exception thrown for lacking ydata";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(ydata => [1, 2, 3]); };
is $@, "must provide at least xydata or both xdata and ydata\n", "exception thrown for lacking xdata";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1], ydata => [1]); };
is $@, "must have more than one data-point\n", "exception thrown for insufficient data";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1, 2], ydata => [1]); };
is $@, "xdata and ydata must have the same number of elements\n", "exception thrown for extraneous xdata";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1], ydata => [1, 2]); };
is $@, "xdata and ydata must have the same number of elements\n", "exception thrown for extraneous ydata";

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1, 2], ydata => [3, 4]); };
ok !$@, "no exceptions when passed xdata, ydata";
is JSON::PP::encode_json($x), '[1,2]', 'xdata returned as xdata';
is JSON::PP::encode_json($y), '[3,4]', 'ydata returned as ydata';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xdata => [1, 2], ydata => [3, 4], inv => 1); };
ok !$@, 'no exceptions when passed xdata, ydata with inverted mode';
is JSON::PP::encode_json($y), '[1,2]', 'xdata returned as ydata with inverted mode';
is JSON::PP::encode_json($x), '[3,4]', 'ydata returned as xdata with inverted mode';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1], [3]]); };
is $@, "pairwise xydata must have two data points per element\n", 'exception thrown for short xydata';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1, 2], [3, 4], [5, 6]]); };
ok !$@, 'no exceptions when passed well-formed xydata';
# print "$@\n";
# print JSON::PP::encode_json(\%Algorithm::CurveFit::Simple::STATS_H)."\n";
is JSON::PP::encode_json($x), '[1,3,5]', 'xdata returned as xdata from xydata';
is JSON::PP::encode_json($y), '[2,4,6]', 'ydata returned as ydata from xydata';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1, 2, 3, 4], [3, 4, 5, 6]]); };
ok !$@, 'no exceptions when passed xdata, ydata';
is JSON::PP::encode_json($x), '[1,2,3,4]', 'xdata returned as xdata from long xydata';
is JSON::PP::encode_json($y), '[3,4,5,6]', 'ydata returned as ydata from long xydata';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1, 2, 3, 4], [3, 4, 5, 6]], inv => 1); };
ok !$@, 'no exceptions when passed xdata, ydata';
is JSON::PP::encode_json($x), '[3,4,5,6]', 'xdata returned as xdata from long xydata with inverted mode';
is JSON::PP::encode_json($y), '[1,2,3,4]', 'ydata returned as ydata from long xydata with inverted mode';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1, 2], [3, 4], [5, 6], [7, 8]]); };
ok !$@, 'no exceptions when passed xydata as paired points';
is JSON::PP::encode_json($x), '[1,3,5,7]', 'xdata returned as xdata from paired-point xydata';
is JSON::PP::encode_json($y), '[2,4,6,8]', 'ydata returned as ydata from paired-point xydata';

($x, $y) = eval { Algorithm::CurveFit::Simple::_init_data(xydata => [[1, 2], [3, 4], [5, 6], [7, 8]], inv => 1); };
ok !$@, 'no exceptions when passed xydata as paired points with inverted mode';
is JSON::PP::encode_json($y), '[1,3,5,7]', 'xdata returned as ydata from paired-point xydata, inverted';
is JSON::PP::encode_json($x), '[2,4,6,8]', 'ydata returned as xdata from paired-point xydata, inverted';

if ($ARGV[0]) {
    print JSON::PP::encode_json(\%Algorithm::CurveFit::Simple::STATS_H)."\n";
}

done_testing();
exit(0);
