#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;
use Array::Windowed qw(array_windowed);
use Data::Dumper;

my @array = ("a".."z");

my $new_array;

$new_array = array_windowed(@array, 0, 26);
is_deeply $new_array, ["a".."z"], "no windowing" or diag Dumper $new_array;

$new_array = array_windowed(@array, 0, 5);
is_deeply $new_array, ["a".."e"], "small window" or diag Dumper $new_array;

$new_array = array_windowed(@array, 1, 5);
is_deeply $new_array, ["b".."f"], "offset" or diag Dumper $new_array;

$new_array = array_windowed(@array, 26, 5);
is_deeply $new_array, [], "outside upper" or diag Dumper $new_array;

$new_array = array_windowed(@array, -50, 5);
is_deeply $new_array, [], "outside lower" or diag Dumper $new_array;

$new_array = array_windowed(@array, 23, 5);
is_deeply $new_array, ["x".."z"], "spanning upper" or diag Dumper $new_array;

$new_array = array_windowed(@array, -2, 5); 
is_deeply $new_array, ["a".."c"], "spanning lower" or diag Dumper $new_array;

$new_array = &array_windowed(\@array, 0, 26);
is_deeply $new_array, ["a".."z"], "pass by ref" or diag Dumper $new_array;