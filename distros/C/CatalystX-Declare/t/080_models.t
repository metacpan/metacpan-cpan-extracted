#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

my $counter = 1;

is get('/model_test/next'), $counter++, 'modifying model'
    for 1 .. 3;

is get('/model_test/reset'), 'reset', 'reset';

$counter = 1;
is get('/model_test/next'), $counter++, 'modifying model'
    for 1 .. 3;


done_testing;
