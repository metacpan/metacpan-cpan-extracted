#!perl

use 5.010;
use strict;
use warnings;

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

my @tests = (
    {schema=>[float => is_nan => 1], input=>1, valid=>0},
    {schema=>[float => is_nan => 1], input=>"Inf", valid=>0},
    {schema=>[float => is_nan => 1], input=>"NaN", valid=>1},

    {schema=>[float => is_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_inf => 1], input=>"-Inf", valid=>1},
    {schema=>[float => is_inf => 1], input=>"Inf", valid=>1},

    {schema=>[float => is_pos_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"-Inf", valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"Inf", valid=>1},

    {schema=>[float => is_neg_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_neg_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_neg_inf => 1], input=>"-Inf", valid=>1},
    {schema=>[float => is_neg_inf => 1], input=>"Inf", valid=>0},
);

test_sah_cases(\@tests);
done_testing();
