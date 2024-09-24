#!perl

use v5.14;
use warnings;

use Test::More;
use SQL::Translator 0.11018;

use lib 't/lib';
use Test::WindowFunctions;

Test::WindowFunctions->run_data_tests(
    files => 't/data',
    match => qr/\.dd$/,
);


done_testing;
