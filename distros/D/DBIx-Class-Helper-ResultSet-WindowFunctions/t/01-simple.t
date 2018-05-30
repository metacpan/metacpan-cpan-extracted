#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Test::WindowFunctions;

Test::WindowFunctions->run_data_tests(
    files => 't/data',
    match => qr/\.dd$/,
);


done_testing;
