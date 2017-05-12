#!perl

use 5.010;
use strict;
use warnings;

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

# basic tests, not in spectest (yet)

my @tests = (
    {schema=>["code"], input=>"a", valid=>0},
    {schema=>["code"], input=>sub{}, valid=>1},
);

test_sah_cases(\@tests);
done_testing();
