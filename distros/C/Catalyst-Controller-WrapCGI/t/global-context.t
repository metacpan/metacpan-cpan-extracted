#!perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 1;
use Catalyst::Test 'TestGC';

is(get('/dummy'), 'dummy', 'global context works');
