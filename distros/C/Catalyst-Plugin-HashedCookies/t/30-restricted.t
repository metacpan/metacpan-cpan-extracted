#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't/lib';

# Check that our module makes the server die if App sets cookie with
# restricted key name.

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('PluginTestApp')); }

use HTTP::Headers::Util 'split_header_words';

{
    ok( my $response = request( '/BadCat' ),
        'Send request to Catalyst, get response' );
        # response will be our request object, serialized

    is( $response->code, 500,
        'Response failed (5xx)' );

    my $cookies = {};

    for my $cookie ( split_header_words( $response->header('Set-Cookie') ) ) {
        $cookies->{ $cookie->[0] } = $cookie;
    }

    ok( ! exists $cookies->{ 'BadCat' },
        'Bad cookie has not been sent to client');
}
