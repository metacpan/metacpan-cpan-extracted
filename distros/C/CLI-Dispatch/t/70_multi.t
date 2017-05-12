use strict;
use warnings;
use lib 't/lib';
use Test::Classy;

load_tests_from 'CLIDTestClass::Multi';
run_tests;
