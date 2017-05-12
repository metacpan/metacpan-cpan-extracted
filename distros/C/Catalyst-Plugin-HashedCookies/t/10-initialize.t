#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use lib 't/lib';

# Tests that check Catalyst is happy with the plugin,
# and that the plugin initializes itself correctly.

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('BasicTestApp')); }

{
    ok( BasicTestApp->config->{hashedcookies}->{key} = 'abcdef0123456789ASDF',
        'Set key to keep HC quiet' );
    isnt( BasicTestApp->setup(), undef,
        'Configuration is sane, setup() goes well' );
        # FIXME perhaps the above isnt() check should be doing something smarter.
        # I've already been bitten by setup() in tests, as it changed return value.

    is( BasicTestApp->config->{hashedcookies}->{algorithm}, 'SHA1',
        'Default algorithm is set' );

    ok( exists BasicTestApp->config->{hashedcookies}->{required},
        'Unspecified "required" is noticed' );
    is( BasicTestApp->config->{hashedcookies}->{required}, '1',
        'Default "required" is set' );
}
