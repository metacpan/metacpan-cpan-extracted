#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use HTTP::Request;
use JSON::MaybeXS;
use Airlock::HTTPMessage;
use AirlockTest;

my $t    = AirlockTest->new;
my $http = Airlock::HTTPMessage->new( airlock => $t->airlock );

sub request {
  my ( $method, $uri, $body, @header ) = @_;
  return HTTP::Request->new( $method, $uri, [ 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'lwp-test/1.0', @header ], $body );
}

subtest 'device' => sub {
  my $response = $http->handle( request( POST => 'https://example.org/airlock/device', 'client_id=cli&scope=read' ), ip => '192.0.2.4' );
  isa_ok( $response, 'HTTP::Response' );
  is( $response->code, 200, 'status' );
  is( $response->message, 'OK', 'status message' );
  is( $response->header('Content-Type'), 'application/json', 'content type' );
  is( $response->header('Cache-Control'), 'no-store', 'no-store' );
  my $json = decode_json( $response->content );
  my $row  = $t->row( $json->{device_code} );
  is( $row->{origin_ip}, '192.0.2.4', 'origin ip from the caller' );
  is( $row->{origin_ua}, 'lwp-test/1.0', 'origin ua from the request' );

  my $poll = $http->handle( request( POST => '/airlock/token', 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code&client_id=cli&device_code='.$json->{device_code} ) );
  is( $poll->code, 400, 'token: status' );
  is( $poll->message, 'Bad Request', 'token: status message' );
  is_deeply( decode_json( $poll->content ), { error => 'authorization_pending' }, 'token: body' );
};

subtest 'refusals' => sub {
  is( $http->handle( request( GET => '/airlock/device' ) )->code, 405, 'GET' );
  is( $http->handle( request( GET => '/airlock/device' ) )->header('Allow'), 'POST', 'Allow header' );
  is( $http->handle( request( POST => '/airlock/nope', 'client_id=cli' ) )->code, 404, 'unknown route' );
  is( $http->handle( HTTP::Request->new( POST => '/airlock/device', [ 'Content-Type' => 'application/json' ], '{"client_id":"cli"}' ) )->code, 400, 'a JSON body is not read' );
  is( $http->handle( HTTP::Request->new( POST => '/airlock/device' ) )->code, 400, 'no body, no headers' );
  is( $http->handle( request( POST => '/airlock/device', 'client_id=cli&pad='.( 'x' x 20000 ) ) )->code, 413, 'a body over the limit' );
};

ok( !eval { Airlock::HTTPMessage->new; 1 }, 'airlock is required' );

done_testing;
