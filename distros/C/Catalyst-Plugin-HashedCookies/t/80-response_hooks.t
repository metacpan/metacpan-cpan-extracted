#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;
use lib 't/lib';
require 'do_request.pl';

# Check that cookies returned in responses from Catalyst are suitably adorned
# with hashedcookie values.

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('PluginTestApp')); }

use HTTP::Headers::Util;

# returned cookies should look like this -- see PluginTestApp.pm
my $expected = { 
    Catalyst => [ qw(
        Catalyst
        _hashedcookies_padding&Cool&_hashedcookies_digest&65e17e8e30702baa1e40080514d09d35a207ddc2
        path
        /
    ) ],
    Cool => [ qw(
        Cool
        _hashedcookies_padding&Catalyst&_hashedcookies_digest&ed7516dabdeff2e7f2c777a400680fe270cd9691
        path
        /
    ) ],
    CoolCat => [ qw(
        CoolCat
        Cool&Catalyst&_hashedcookies_digest&58d48ba748607b0c3652052635d00005c2d2e2e3
        path
        /
    ) ],
};

{
    for my $url (qw( /Catalyst/Cool /CoolCat /CoolCat/Catalyst /Cool/CoolCat )) {

        my (undef, $response, undef) = &do_request( $url );
        my $cookies = {};

        if ($HTTP::Headers::Util::VERSION >= 5.817) {
            for my $cookie ( HTTP::Headers::Util::_split_header_words( $response->header('Set-Cookie') ) ) {
                $cookies->{ $cookie->[0] } = $cookie;
            }
        }
        else {
            for my $cookie ( HTTP::Headers::Util::split_header_words( $response->header('Set-Cookie') ) ) {
                $cookies->{ $cookie->[0] } = $cookie;
            }
        }

        is_deeply( $cookies, { map {$_ => $expected->{$_}} grep {$_} split '/', $url },
            'Returned cookies are correct');
    }
}
