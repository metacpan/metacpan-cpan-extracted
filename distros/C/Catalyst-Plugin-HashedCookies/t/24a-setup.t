#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use lib 't/lib';

# Tests for various ways in which setup() can complain or die

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('BasicTestApp')); }

{
    ok( BasicTestApp->config->{hashedcookies}->{key} = 'abcdef0123456789ASDF',
        'Re-set key to keep HashedCookies quiet' );
    is( BasicTestApp->config->{hashedcookies}->{algorithm} = '', '',
        'Set algorithm to empty string' ); 

    isnt( BasicTestApp->setup(), undef,
        'Setup copes with empty string algorithm' );
        # FIXME perhaps the above isnt() check should be doing something smarter.
        # I've already been bitten by setup() in tests, as it changed return value.

    is( BasicTestApp->config->{hashedcookies}->{algorithm}, 'SHA1',
        'Default algorithm is set' );
}
