#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use JSON::MaybeXS;
use AirlockTest;

my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

sub psgi {
  my ( $app, %arg ) = @_;
  my $body = $arg{body} // '';
  CORE::open( my $input, '<', \$body ) or die $!;
  my $response = $app->( {
    REQUEST_METHOD    => $arg{method} // 'POST',
    PATH_INFO         => $arg{path},
    CONTENT_TYPE      => exists $arg{type} ? $arg{type} : 'application/x-www-form-urlencoded',
    CONTENT_LENGTH    => exists $arg{length} ? $arg{length} : length $body,
    REMOTE_ADDR       => '192.0.2.9',
    HTTP_USER_AGENT   => 'test-agent/1.0',
    'psgi.input'      => $input
  } );
  my %header = @{ $response->[1] };
  return ( $response->[0], \%header, decode_json( join '', @{ $response->[2] } ) );
}

subtest 'respond: routes' => sub {
  my $t = AirlockTest->new;
  my ( $status, $headers, $json ) = @{ $t->airlock->respond( 'POST', '/device', { client_id => 'cli', scope => 'read' }, { ip => '192.0.2.9' } ) };
  is( $status, 200, 'device: 200' );
  is( $headers->{'Content-Type'}, 'application/json', 'content type' );
  is( $headers->{'Cache-Control'}, 'no-store', 'no-store' );
  ok( $json->{device_code} && $json->{user_code}, 'device authorization response' );

  for my $path ( '/airlock/device', 'device', '/device/', '/a/b/c/device' ) {
    is( $t->airlock->respond( 'POST', $path, { client_id => 'cli' }, {} )->[0], 200, 'mounted at '.$path );
  }
  is_deeply( [ @{ $t->airlock->respond( 'POST', '/nope', {}, {} ) }[ 0, 2 ] ], [ 404, { error => 'not_found' } ], 'unknown route' );
  is( $t->airlock->respond( 'POST', '/devices', {}, {} )->[0], 404, 'a longer segment is not the route' );
  is( $t->airlock->respond( 'POST', '', {}, {} )->[0],    404, 'empty path' );
  is( $t->airlock->respond( 'POST', undef, {}, {} )->[0], 404, 'undef path' );

  my $get = $t->airlock->respond( 'GET', '/device', { client_id => 'cli' }, {} );
  is( $get->[0], 405, 'GET is refused' );
  is( $get->[1]{Allow}, 'POST', 'with an Allow header' );
  is( $t->airlock->respond( 'post', '/device', { client_id => 'cli' }, {} )->[0], 200, 'method is case-insensitive' );
  is_deeply( [ @{ $t->airlock->respond( 'POST', '/device', undef, {} ) }[ 0, 2 ] ], [ 400, { error => 'invalid_request' } ], 'unparseable parameters' );
};

subtest 'respond: token' => sub {
  my $t     = AirlockTest->new;
  my $start = $t->airlock->respond( 'POST', '/device', { client_id => 'cli' }, {} )->[2];
  my $poll  = sub { [ @{ $t->airlock->respond( 'POST', '/token', { grant_type => $grant, client_id => 'cli', device_code => $start->{device_code}, @_ }, {} ) }[ 0, 2 ] ] };

  is_deeply( $poll->(), [ 400, { error => 'authorization_pending' } ], 'pending' );
  is_deeply( $poll->( grant_type => 'password' ), [ 400, { error => 'unsupported_grant_type' } ], 'another grant type' );
  is_deeply( $poll->( grant_type => undef ),      [ 400, { error => 'unsupported_grant_type' } ], 'no grant type' );
  is_deeply( $poll->( device_code => undef ),     [ 400, { error => 'invalid_request' } ],        'no device code' );
  is_deeply( $poll->( client_id => 'open' ),      [ 400, { error => 'invalid_grant' } ],          'another client' );

  $t->airlock->approve( $start->{user_code}, subject => { id => 'alice' } );
  $t->advance(5);
  my $granted = $poll->();
  is( $granted->[0], 200, 'granted' );
  is( $granted->[1]{token_type}, 'Bearer', 'token response' );
  ok( $t->airlock->verify_token( $granted->[1]{access_token} ), 'the token verifies' );
};

subtest 'parse_form' => sub {
  my $airlock = AirlockTest->new->airlock;
  is_deeply( $airlock->parse_form('a=1&b=two'), { a => 1, b => 'two' }, 'pairs' );
  is_deeply( $airlock->parse_form('scope=read+write&x=%41%2fb%3D'), { scope => 'read write', x => 'A/b=' }, 'plus and percent' );
  is_deeply( $airlock->parse_form('a=1=2'), { a => '1=2' }, 'only the first = splits' );
  is_deeply( $airlock->parse_form('flag&b='), { flag => '', b => '' }, 'no value and empty value' );
  is_deeply( $airlock->parse_form(''),    {}, 'empty' );
  is_deeply( $airlock->parse_form(undef), {}, 'undef' );
  is_deeply( $airlock->parse_form('&&a=1&'), { a => 1 }, 'empty pairs are skipped' );
  is( $airlock->parse_form('a=1&a=2'), undef, 'a repeated parameter is refused' );
  is_deeply( $airlock->parse_form('a=%zz'), { a => '%zz' }, 'a broken escape stays as it is' );
};

subtest 'to_app' => sub {
  my $t   = AirlockTest->new;
  my $app = $t->airlock->to_app;

  my ( $status, $headers, $json ) = psgi( $app, path => '/device', body => 'client_id=cli&scope=read+write' );
  is( $status, 200, 'device: 200' );
  is( $headers->{'Content-Type'}, 'application/json', 'content type' );
  is( $headers->{'Cache-Control'}, 'no-store', 'no-store' );
  my $row = $t->row( $json->{device_code} );
  is( $row->{scope}, 'read write', 'the form body was decoded' );
  is( $row->{origin_ip}, '192.0.2.9', 'origin ip from REMOTE_ADDR' );
  is( $row->{origin_ua}, 'test-agent/1.0', 'origin ua from the header' );

  my $token_body = 'grant_type='.$grant =~ s/:/%3A/gr.'&client_id=cli&device_code='.$json->{device_code};
  is_deeply( [ ( psgi( $app, path => '/token', body => $token_body ) )[ 0, 2 ] ], [ 400, { error => 'authorization_pending' } ], 'token: pending' );

  is( ( psgi( $app, path => '/device', method => 'GET' ) )[0], 405, 'GET' );
  is( ( psgi( $app, path => '/other', body => 'client_id=cli' ) )[0], 404, 'unknown route' );
  is_deeply( [ ( psgi( $app, path => '/device', body => 'client_id=cli&client_id=open' ) )[ 0, 2 ] ], [ 400, { error => 'invalid_request' } ], 'repeated parameter' );
  is_deeply( [ ( psgi( $app, path => '/device', body => '{"client_id":"cli"}', type => 'application/json' ) )[ 0, 2 ] ], [ 400, { error => 'invalid_client' } ], 'a JSON body is not read' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', type => 'application/x-www-form-urlencoded; charset=UTF-8' ) )[0], 200, 'content type with a charset' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', type => undef ) )[0], 400, 'no content type' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli&pad='.( 'x' x 20000 ) ) )[0], 413, 'a body over the limit is refused unread' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', length => 100 ) )[0], 200, 'a body shorter than its Content-Length does not hang' );
  is( ( psgi( $app, path => '/device', body => '', length => 0 ) )[0], 400, 'an empty body' );
  for my $bad ( '13abc', 'abc', '-1', '1.5', ' 13' ) {
    is_deeply( [ ( psgi( $app, path => '/device', body => 'client_id=cli', length => $bad ) )[ 0, 2 ] ], [ 400, { error => 'invalid_request' } ], 'Content-Length "'.$bad.'" is refused' );
  }
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', length => undef ) )[0], 400, 'no Content-Length reads no body' );
};

done_testing;
