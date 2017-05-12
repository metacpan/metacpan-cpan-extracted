use strict;
use warnings;
use lib 't/lib';
use Test::Classy;

load_tests_from 'CLIDTestClass::Inline';
run_tests;
