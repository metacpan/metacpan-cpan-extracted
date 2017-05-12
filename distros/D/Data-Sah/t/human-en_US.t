#!perl

# some checks for human compilation (lang=en_US). currently only for sanity, not
# thorough at all.

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Data::Sah::Human qw(test_human);

my @tests = (
    {schema=>"int",
     result=>"integer"},
    {schema=>"int*",
     result=>"integer"},
    {schema=>[int => min=>1],
     result=>"integer, must be at least 1"},
    {schema=>[int => min=>1, max=>10],
     result=>"integer, must be at least 1, must be at most 10"},
    {schema=>[int => "div_by&" => [2, 5]],
     result=>"integer, must be divisible by 2 and 5"},
    {schema=>[int => "div_by&" => [2, 3, 5]],
     result=>"integer, must be divisible by all of [2,3,5]"},
    {schema=>[int => "div_by|" => [2, 5]],
     result=>"integer, must be divisible by 2 or 5"},
    {schema=>[int => "div_by|" => [2, 3, 5]],
     result=>"integer, must be divisible by one of [2,3,5]"},
    {schema=>[int => "!div_by" => 5],
     result=>"integer, must not be divisible by 5"},

    # array
    {schema=>[array => of => "int"],
     result=>"array of integers"},
    {schema=>[array => of => [int => min=>1]],
     result=>qr/array .+ each\sarray\selement\smust\sbe: .+
                integer .+ at\sleast\s1/x},
    # -- test ordinate()
    {schema=>[array => elems => ["int"]],
     result=>"array, 1st element must be: integer"},

    # all
    {schema=>[all => of => [[int => div_by=>2], [int => div_by=>5]]],
     result=>qr/must\sbe\sall\sof\sthe\sfollowing: .+
                integer.+even .+
                integer.+divisible\sby\s5 .+
               /x},

    # hash
    {schema=>[hash => keys => {i=>[int => min=>0], f=>"float"}],
     result=>"hash, field f must be: decimal number, field i must be: (integer, must be at least 0)"},
);

# XXX use test_sah_cases() when it supports js
for my $test (@tests) {
    test_human(lang=>"en_US", %$test);
}
done_testing;
