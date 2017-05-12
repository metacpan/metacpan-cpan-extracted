#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 'no_plan';

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestApp');
}

use Catalyst::Test 'TestApp';

my ($res);

$res = request('/');

