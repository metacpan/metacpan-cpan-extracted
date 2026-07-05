#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use AEPS_TestSuite;

diag 'backend: ' . Algorithm::EventsPerSecond->backend
    . ( Algorithm::EventsPerSecond->simd ? ' (' . Algorithm::EventsPerSecond->simd . ')' : '' );

AEPS_TestSuite::run_suite();

done_testing();
