#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use lib 't/lib';

# Tests for various ways in which setup() can complain or die

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('BasicTestApp')); }

{
    is( undef BasicTestApp->config->{hashedcookies}, undef,
        'Obliterate BasicTestApp\'s hash key and param defaults' );
    ok( BasicTestApp->config->{hashedcookies}->{key} = 'abcdef0123456789ASDF',
        'Re-set key to keep HashedCookies quiet' );

    is( undef BasicTestApp->config->{hashedcookies}->{algorithm}, undef,
        'Provide an undef algorithm' );

    isnt( BasicTestApp->setup(), undef,
        'Setup copes with undef algorithm' );
        # FIXME perhaps the above isnt() check should be doing something smarter.
        # I've already been bitten by setup() in tests, as it changed return value.

    is( BasicTestApp->config->{hashedcookies}->{algorithm}, 'SHA1',
        'Default algorithm is set' );
}
