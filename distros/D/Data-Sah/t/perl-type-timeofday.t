#!perl

# minimal and temporary tests, pending real timeofday spectest from Sah

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

plan skip_all => "Date::TimeOfDay not available" unless eval { require Date::TimeOfDay; 1 };

use Test::Data::Sah qw(test_sah_cases);

my @tests = (
    {schema=>["timeofday"], input=>"23:59:59", valid=>1},
    {schema=>["timeofday"], input=>"foo", valid=>0},
    {schema=>["timeofday"], input=>"24:00:00", valid=>0},
    {schema=>["timeofday"], input=>Date::TimeOfDay->now_local, valid=>1},

    {schema=>["timeofday", min=>"12:00:00"], input=>"11:59:59", valid=>0},
    {schema=>["timeofday", min=>"12:00:00"], input=>"12:00:00", valid=>1},
    {schema=>["timeofday", min=>"12:00:00"], input=>"12:00:01", valid=>1},
    {schema=>["timeofday", xmin=>"12:00:00"], input=>"12:00:00.05", valid=>1},
);

test_sah_cases(\@tests);
done_testing();
