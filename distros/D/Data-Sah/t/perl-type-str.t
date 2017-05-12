#!perl

use 5.010;
use strict;
use warnings;

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

my @tests = (
    # test that match in perl accepts regexp object too
    {schema=>["str*", match=>qr!/!], input=>"a" , valid=>0},
    {schema=>["str*", match=>qr!/!], input=>"a/", valid=>1},
);

test_sah_cases(\@tests);
done_testing();
