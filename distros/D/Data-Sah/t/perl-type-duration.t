#!perl

# minimal and temporary tests, pending real duration spectest from Sah

use 5.010;
use strict;
use warnings;

use Test::More 0.96;
use Test::Data::Sah qw(test_sah_cases);

plan skip_all => "DateTime::Duration not available" unless eval { require DateTime::Duration; 1 };
plan skip_all => "Time::Duration::Parse::AsHash not available" unless eval { require Time::Duration::Parse::AsHash; 1 };

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["duration"], input=>"P1Y2M", valid=>1},

    {schema=>["duration"], input=>"2 days 13 hours", valid=>1},
    {schema=>["duration"], input=>"2 xxx", valid=>0},

    {schema=>["duration"], input=>"1", valid=>1},
    {schema=>["duration"], input=>"864000", valid=>1},
    #{schema=>["duration"], input=>"-3600", valid=>0}, # Time::Duration::Parse::AsHash interprets and accepts this

    {schema=>["duration"], input=>"x", valid=>0},
    {schema=>["duration"], input=>"1Y2M", valid=>0},

    {schema=>["duration"], input=>DateTime::Duration->new(years=>1, months=>2), valid=>1},
);

test_sah_cases(\@tests);
done_testing();
