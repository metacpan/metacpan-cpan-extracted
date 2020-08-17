#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Class::Measure;

{ package MeasureTest; use base qw( Class::Measure ); }

MeasureTest->reg_units(
    qw(example1 example2)
);
MeasureTest->reg_convs(
    2e-1, 'example1' => 'example2',
);
my $example = MeasureTest->new(1, 'example1');
ok( ($example->example2 == 5), 'handle exponential notation');

done_testing;
