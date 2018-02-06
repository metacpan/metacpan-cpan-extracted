#!/bin/env perl
use strict;
use warnings;
use Test::Most;
use JSON::PP;

use lib "./lib";
use Algorithm::CurveFit::Simple;

my $p = eval { Algorithm::CurveFit::Simple::_init_parameters([3, 5, 7, 9], [1, 2, 3, 4]); };
is_deeply $p, [["k", 2.5, 1e-07], ["a", 0.5, 1e-07], ["b", 0.5, 1e-07], ["c", 0.5, 1e-07]], 'default parameters';

$p = eval { Algorithm::CurveFit::Simple::_init_parameters([3, 5, 7, 9], [1, 2, 3, 4], terms => 2); };
is_deeply $p, [["k", 2.5, 1e-07], ["a", 0.5, 1e-07], ["b", 0.5, 1e-07]], 'explicit term parameters';

if ($ARGV[0]) {
    print JSON::PP::encode_json(\%Algorithm::CurveFit::Simple::STATS_H)."\n";
}

done_testing();
exit(0);
