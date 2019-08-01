#!perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.98;

# basic tests, not in spectest (yet)

my @tests = (
    # if(expr, then schema)
    #   basic
    {schema=>["num", if=>['$data > 1', ["int*", div_by=>2]]], input=>1, valid=>1},
    {schema=>["num", if=>['$data > 1', ["int*", div_by=>2]]], input=>2, valid=>1},
    {schema=>["num", if=>['$data > 1', ["int*", div_by=>2]]], input=>3, valid=>0},

    #   multiple values (AND)
    {schema=>["num", 'if&'=>[  ['$data > 1', ["int*", div_by=>2]], ['$data > 2', ["int*", div_by=>3]]  ]], input=>1, valid=>1},
    {schema=>["num", 'if&'=>[  ['$data > 1', ["int*", div_by=>2]], ['$data > 2', ["int*", div_by=>3]]  ]], input=>2, valid=>1},
    {schema=>["num", 'if&'=>[  ['$data > 1', ["int*", div_by=>2]], ['$data > 2', ["int*", div_by=>3]]  ]], input=>3, valid=>0},
    {schema=>["num", 'if&'=>[  ['$data > 1', ["int*", div_by=>2]], ['$data > 2', ["int*", div_by=>3]]  ]], input=>4, valid=>0},
    {schema=>["num", 'if&'=>[  ['$data > 1', ["int*", div_by=>2]], ['$data > 2', ["int*", div_by=>3]]  ]], input=>6, valid=>1},
);

test_sah_cases(\@tests);
done_testing;
