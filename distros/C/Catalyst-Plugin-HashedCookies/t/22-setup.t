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

    ok( BasicTestApp->config->{hashedcookies}->{algorithm} = 'MD5',
        'Set alternate algorithm to default of SHA1' );
    isnt( BasicTestApp->setup(), undef,
        'Setup is happy with alternate algorithm' );
        # FIXME perhaps the above isnt() check should be doing something smarter.
        # I've already been bitten by setup() in tests, as it changed return value.
    is( BasicTestApp->config->{hashedcookies}->{algorithm}, 'MD5',
        'Setup hasn\'t altered our algorithm' );
}
