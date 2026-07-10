#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

# force the pure Perl backend before the module is loaded
BEGIN { $ENV{ALGORITHM_EVENTSPERSECOND_PP} = 1 }

use lib 't/lib';
use AEPS_TestSuite;

is( Algorithm::EventsPerSecond->backend, 'PP',  'ALGORITHM_EVENTSPERSECOND_PP forces the pure Perl backend' );
is( Algorithm::EventsPerSecond->simd,    undef, 'simd is undef on the pure Perl backend' );

AEPS_TestSuite::run_suite();

done_testing();
