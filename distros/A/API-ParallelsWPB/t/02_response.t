#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;
use API::ParallelsWPB::Response;
use HTTP::Response;
use API::ParallelsWPB;

subtest 'Response ok' => sub {

    plan tests => 3;

    my $r = HTTP::Response->new;
    $r->code( 200 );
    $r->content( '{"response":"b6a09c08f880f229c091de03b91bdbc3"}' );

    my $response = API::ParallelsWPB::Response->new( $r );

    ok( $response->success, 'Response status succeeded' );
    is(
        $response->response,
        'b6a09c08f880f229c091de03b91bdbc3',
        'Response content is ok'
    );

    is( $response->status, '200 OK', 'Status line is ok' );
};

subtest 'Response errored' => sub {

    plan tests => 4;

    my $r = HTTP::Response->new;
    $r->code( 404 );
    $r->content(
'{"error":{"message":"Requested resource does not exist by URI: /api/5.3/sites/"}}'
    );

    my $response = API::ParallelsWPB::Response->new( $r );
    ok( !$response->success, 'Response is not succeeded' );
    like(
        $response->error,
        qr/Requested resource does not exist/,
        'Error message is ok'
    );

    ok( !$response->response, 'No content given ok' );
    is( $response->status, '404 Not Found', 'Response status is ok' );
};