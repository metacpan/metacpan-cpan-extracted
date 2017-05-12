#!/usr/bin/env perl

use lib::abs './lib';

use warnings;
use strict;

use Test::More;
use Catalyst::Test 'TestApp';

is get('/'), 7;

done_testing;