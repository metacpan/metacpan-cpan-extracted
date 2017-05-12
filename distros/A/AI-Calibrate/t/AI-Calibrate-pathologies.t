#  -*- Mode: CPerl -*-
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Calibrate.t'

use Test::More tests => 6;
BEGIN { use_ok('AI::Calibrate', ':all') };

my $points0 = [ ];


use Data::Dumper;

is_deeply( calibrate($points0), [], "empty point set");

my $points1 = [
    [.9, 1]
    ];

is_deeply(calibrate($points1), [[0.9,1]], "Singleton point set");

my $points2 = [
    [.8, 1],
    [.7, 0],
    ];

is_deeply(calibrate($points2), [[0.8, 1]], "two-point perfect");

my $points3 = [
    [.8, 0],
    [.7, 1],
    ];

is_deeply(calibrate($points3), [[0.7, 0.5]], "two-point anti-perfect");

my $points4 = [
    [.8, 0],
    [.8, 1],
    ];

is_deeply(calibrate($points4), [[0.8, 0.5]], "two-point conflicting");
