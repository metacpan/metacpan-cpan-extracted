#!perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.98;

# basic tests, not in spectest (yet)

my @tests = (
    # expr in clause value
    {schema=>["int", "min=", "2**3"], input=>0, valid=>0},
    {schema=>["int", "min=", "2**3"], input=>2, valid=>0},
    {schema=>["int", "min=", "2**3"], input=>3, valid=>0},
    {schema=>["int", "min=", "2**3"], input=>8, valid=>1},
);

test_sah_cases(\@tests);
done_testing;
