#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use lib 't/lib';

# Tests for various ways in which setup() can complain or die

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('BasicTestApp')); }

{
    is( undef BasicTestApp->config->{hashedcookies}, undef,
        'Obliterate BasicTestApp\'s hash key and param defaults' );
    is( eval{ BasicTestApp->setup() }, undef,
        'Setup dies without a key' );
}
