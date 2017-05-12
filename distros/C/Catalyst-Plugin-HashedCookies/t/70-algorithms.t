#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 73;
use lib 't/lib';
require 'do_request.pl';

# Tests to exercise our plugin's hashing and vailidity checks

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('PluginTestApp')); }

use HTTP::Request::Common;

my @cookies = (
    # These first four check that the plugin strips special _hashedcookies_*
    # fields from the cookies within the Catalyst request phase, and then also
    # check that "required" defaults to '1', meaning cookies with hashes are
    # valid but those without are invalid (well, not valid, in this check).
    ['_hashedcookies_padding&one', 'one', ''],
    ['_hashedcookies_padding&one&_hashedcookies_digest&d36978d8a21991c14b9cf6d086313837f321d392', 'one', 1],
    ['one&two', 'one&two', ''],
    ['one&two&_hashedcookies_digest&c1cae8fae8a4f89541798e61d1609bea2d7d3c3a', 'one&two', 1],

    # Now we're going to check that multiple cookies in one request are
    # processed successfully, and set to be valid or invalid.
    'one&two&_hashedcookies_digest&f60e9a312547fd9e8056169874daf7e530a2a37d',
    'one&two&_hashedcookies_digest&4bdccd2c28a2c67c85b002cbfba4e089817e9f33',
    'one&two&_hashedcookies_digest&b3357075cd6c2c58e41b38fbfe78d14683a768b0', # nok
    'one&two&_hashedcookies_digest&e72089642d313d216d4b1bda1a54a2d8825fc724', # nok
    'one&two',

    # This last block runs with "require" disabled, so that the third cookie
    # is neither invalid nor valid.
    'one&two&_hashedcookies_digest&60c590f3c7aedb57befdcb48e4384e5f94c64393',
    'one&two&_hashedcookies_digest&60c590f3c7aedb57befdcb48e4384e5f94c64393', # nok
    'one&two',
);


{
    # four cookies to test
    for (my $i = 0; $i <= 3; ++$i) {
    
        my $request = HTTP::Request::Common::GET(
            '/',
            'Cookie' => "HC$i=". $cookies[$i]->[0],
        );

        my ($creq, $response, undef) = &do_request( $request );
        
        isa_ok( $creq->cookies->{"HC$i"}, 'CGI::Simple::Cookie',
            "Cookie \"HC$i\"" );
        is( $creq->cookies->{"HC$i"}->as_string, "HC$i=". $cookies[$i]->[1] .'; path=/',
            "Cookie \"HC$i\" handled by HashedCookies" );
        is( $creq->valid_cookie("HC$i"), $cookies[$i]->[2],
            "HC$i Authentication check" ) or diag( $response->content );
    }
}

{
    my $request = GET(
        '/',
        'Cookie' => "HC4=$cookies[4]; HC5=$cookies[5]; HC6=$cookies[6]; HC7=$cookies[7]; HC8=$cookies[8]",
    );

    my $creq = &do_request( $request );

    isa_ok( $creq->cookies->{'HC4'}, 'CGI::Simple::Cookie', "Cookie HC4 exists" );
    isa_ok( $creq->cookies->{'HC5'}, 'CGI::Simple::Cookie', "Cookie HC5 exists" );
    isa_ok( $creq->cookies->{'HC6'}, 'CGI::Simple::Cookie', "Cookie HC6 exists" );
    isa_ok( $creq->cookies->{'HC7'}, 'CGI::Simple::Cookie', "Cookie HC7 exists" );
    isa_ok( $creq->cookies->{'HC8'}, 'CGI::Simple::Cookie', "Cookie HC8 exists" );

    # required is on, so no hash will be invalid
    is( $creq->valid_cookie('HC4'),   1,  'HC4 Authentication check' );
    is( $creq->valid_cookie('HC5'),   1,  'HC5 Authentication check' );
    is( $creq->invalid_cookie('HC6'), 1,  'HC6 Authentication check' );
    is( $creq->invalid_cookie('HC7'), 1,  'HC7 Authentication check' );
    is( $creq->valid_cookie('HC8'),   '', 'HC8 Authentication check' );
    is( $creq->invalid_cookie('HC8'), 1,  'HC8 Authentication check (2)' );
}

{
    PluginTestApp->config->{hashedcookies}->{required} = 0;

    my $request = GET( 'http://localhost/dump/request',
        'Cookie' => "HC9=$cookies[9]; HC10=$cookies[10]; HC11=$cookies[11]",
    );

    my $creq = &do_request( $request );

    isa_ok( $creq->cookies->{'HC9'},  'CGI::Simple::Cookie', "Cookie HC9 exists" );
    isa_ok( $creq->cookies->{'HC10'}, 'CGI::Simple::Cookie', "Cookie HC10 exists" );
    isa_ok( $creq->cookies->{'HC11'}, 'CGI::Simple::Cookie', "Cookie HC11 exists" );

    # required is off, so no hash will be ignored
    is( $creq->valid_cookie('HC9'),    1,  'HC9 Authentication check' );
    is( $creq->invalid_cookie('HC10'), 1,  'HC10 Authentication check' );
    is( $creq->valid_cookie('HC11'),   '', 'HC11 Authentication check' );
    is( $creq->invalid_cookie('HC11'), '', 'HC11 Authentication check (2)' );
}
