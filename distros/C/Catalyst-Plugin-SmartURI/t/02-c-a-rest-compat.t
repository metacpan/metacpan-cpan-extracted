#!perl

use strict;
use warnings;
use Test::More tests => 1;
use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';

SKIP: {

skip 'Catalyst::Action::REST not installed', 1
    if eval { require Catalyst::Action::REST }, $@;

is(get('/foo'), '/foo?foo=bar',
    'C::A::REST and SmartURI are both functional');

}

# vim: expandtab shiftwidth=4 ts=4 tw=80:
