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
    'example1' => 'example2', sub { return shift },
);
my $example = MeasureTest->new(1, 'example1');
ok( ($example->example2 == 1), 'convert via sub');

done_testing;
