#!perl

use Test::Most;

use HTTP::Request;
use HTTP::Request::Common;

use lib 't/lib';

use Catalyst::Test 'TestApp';

my @Methods =
  map { "is_" . $_ } qw/ get head post put delete connect options trace patch propfind /;

subtest 'HEAD' => sub {

    my ( $res, $c ) = ctx_request( HEAD '/' );
    can_ok( $c->req, @Methods );

    ok $res->is_success, 'HEAD /';

    ok $c->req->is_head, 'is_head';
    ok !$c->req->is_get, '!is_get';

};

subtest 'GET' => sub {

    my ( $res, $c ) = ctx_request( GET '/' );

    ok $res->is_success, 'GET /';

    ok $c->req->is_get, 'is_get';
    ok !$c->req->is_post, '!is_post';

};

subtest 'POST' => sub {

    my ( $res, $c ) = ctx_request( POST '/' );

    ok $res->is_success, 'POST /';

    ok $c->req->is_post, 'is_post';
    ok !$c->req->is_get, '!is_get';

};

subtest 'Unrecognized HTTP method' => sub {

    my ( $res, $c ) = ctx_request( HTTP::Request->new( SPORK => '/' ) );

    ok $c->req->is_unrecognized_method;
};

done_testing;
