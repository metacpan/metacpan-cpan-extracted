#!/bin/env perl
use strict;
use warnings;
use Test::Most;
use Time::HiRes;
use JSON::PP;

use lib "./lib";
use Algorithm::CurveFit::Simple qw(fit %STATS_H);

# Pass an argument for profiling purposes, will also dump source code string and statistics
my $N_TERMS = int($ARGV[0] // 0) || '3';
my $LANG    = $ARGV[1] // 'perl';

my $tm0 = Time::HiRes::time();
my ($max_dev, $avg_dev, $src) = eval { fit(terms => $N_TERMS, xydata => [[1, 3], [2, 7], [3, 11], [4, 19], [5, 35], [6, 54], [7, 69], [8, 81], [9, 90], [10, 96]], impl_lang => $LANG); };
print "# exception: $@\n" if ($@);
my $tm_elapsed = Time::HiRes::time() - $tm0;

ok !$@, "no thrown exceptions";
ok $tm_elapsed // 0 <= 4.0, "time elapsed is within expectations";
ok $max_dev    // 0 <= 1.4, "maximum deviation is within expectations";
ok $avg_dev    // 0 <= 1.1, "average deviation is within expectations";

if ($ARGV[0]) {
    print "$src\n";
    print JSON::PP::encode_json([$max_dev, $avg_dev, \%STATS_H])."\n";
}

done_testing();
exit(0);
