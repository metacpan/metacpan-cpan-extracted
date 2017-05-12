#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::sfx_year_range';
    use_ok $pkg;
}

#---
my $parsed = $pkg->new('years')->fix({years => [1900,1901,1920,1980,1981,1982]});

ok $parsed , 'parsing years';

is $parsed->{years} , "1900 - 1901 ; 1920 ; 1980 - 1982" , "correct human string";

done_testing 3;
