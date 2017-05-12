#!perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';
use Test::More tests => 1;

is(get('/test_my_uri'), '/dummy?foo=bar', 'configured uri_class');

# vim: expandtab shiftwidth=4 ts=4 tw=80:
