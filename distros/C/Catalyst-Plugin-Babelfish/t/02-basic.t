#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

run_tests();

sub run_tests {
    #test plural forms

    # test default dictionary
    {
        my $expected = 'Hello';

        my ( $response, $ctx ) = ctx_request("/hello");
        is ( $response->content, $expected, 'en ok');

    }

    #test fr dictionary

    {
        my $expected = 'Bonjour';

        my ( $response, $ctx ) = ctx_request("/hello?lang=fr_FR");
        is ( $response->content, $expected, 'fr dynamic ok');
    }


    #test set_lang

    {
        my $expected = 'Bonjour';

        my ( $response, $ctx ) = ctx_request("/hello_fr");

        is ( $response->content, $expected, 'fr static ok');

    }

    {
        my $expected = 'I have 1 nail';

        my ( $response, $ctx ) = ctx_request("/plural/?count=1");
        is ( $response->content, $expected, 'plural 1 ok');

    }

    {
        my $expected = 'I have 10 nails';

        my ( $response, $ctx ) = ctx_request("/plural/?count=10");
        is ( $response->content, $expected, 'plural 2 ok');

    }



}
