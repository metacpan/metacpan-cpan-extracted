#!/usr/bin/env perl

#
# Copyright (C) 2021-2023 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use App::RouterColorizer;
use File::ByLine 1.192590;
use File::Spec;
use FindBin qw( $Bin );
use List::Util qw(1.56 zip);

my $testname = "05-junos";

my $colorizer = App::RouterColorizer->new();

my (@input)    = readlines(File::Spec->catfile($Bin, "data", "$testname.input"));
my (@expected) = readlines(File::Spec->catfile($Bin, "data", "$testname.output"));
my (@output)   = map { $colorizer->format_text($_) } @input;

for my $test (zip \@input, \@expected, \@output) {
    my ($in, $expected, $out) = @$test;

    is( $out, $expected, $in );
}

done_testing;
1;

