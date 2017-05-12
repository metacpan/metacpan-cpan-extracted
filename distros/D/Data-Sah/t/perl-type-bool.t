#!perl

use 5.010;
use strict;
use warnings;

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["bool*", is_true=>0], input=>"", valid=>1},
    {schema=>["bool*", is_true=>1], input=>"a", valid=>1},
    {schema=>["bool*", is_true=>1], input=>0.1, valid=>1},
);

test_sah_cases(\@tests);
done_testing();
