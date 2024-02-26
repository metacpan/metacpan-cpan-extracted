#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t = Data::Transfigure->bare();

is(ref($t), 'Data::Transfigure', 'constructor');

done_testing;
