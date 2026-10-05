#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

use HTTP::Server::PSGI;
use Test::TCP;
use JSON::MaybeXS;
use Airlock::Client;
use AirlockTest;

# A stand-in for HTTP::Tiny that talks to a PSGI app in-process: no socket, no
# second process, so the test and the server share one clock and one store.
{
  package LocalUA;
  use Moo;
  extends 'HTTP::Tiny';
  has app  => ( is => 'ro', required => 1 );
  has seen => ( is => 'ro', default => sub { [] } );

  sub request {
    my ( $self, $method, $url, $args ) = @_;
    my $body = $args->{content} // '';
    my ( $path ) = $url =~ m{\Ahttps?://[^/]+(/[^?]*)};
    push @{ $self->seen }, { method => $method, url => $url, body => $body, headers => $args->{headers} };
    CORE::open( my $input, '<', \$body ) or die $!;
    my $psgi = $self->app->( {
      REQUEST_METHOD  => $method,
      PATH_INFO       => $path,
      CONTENT_TYPE    => $args->{headers}{'content-type'},
      CONTENT_LENGTH  => length $body,
      REMOTE_ADDR     => '127.0.0.1',
      HTTP_USER_AGENT => 'local-ua',
      'psgi.input'    => $input
    } );
    return {
      success => $psgi->[0] < 400 ? 1 : '',
      status  => $psgi->[0],
      reason  => 'local',
      content => join( '', @{ $psgi->[2] } ),
      headers => { @{ $psgi->[1] } }
    };
  }
}

sub fixture {
  my ( %arg ) = @_;
  my $t   = AirlockTest->new;
  my $app = delete $arg{app} || $t->airlock->to_app;
  my @slept;
  my $after_sleep = delete $arg{after_sleep} || sub { };
  my $ua     = LocalUA->new( app => $app );
  my $client = Airlock::Client->new(
    client_id       => 'cli',
    scope           => 'read write',
    device_endpoint => 'http://airlock.test/airlock/device',
    token_endpoint  => 'http://airlock.test/airlock/token',
    ua              => $ua,
    now             => sub { $t->clock },
    sleep           => sub { push @slept, $_[0]; $t->advance( $_[0] ); $after_sleep->( $t, scalar @slept ) },
    on_prompt       => sub { },
    %arg
  );
  return ( $t, $client, \@slept, $ua );
}

subtest 'start' => sub {
  my ( $t, $client, undef, $ua ) = fixture();
  my $start = $client->start;
  like( $start->{device_code}, qr/\A[0-9a-f]{64}\z/, 'device_code' );
  like( $start->{user_code}, qr/\A\w{4}-\w{4}\z/, 'user_code' );
  is( $t->row( $start->{device_code} )->{scope}, 'read write', 'the scope arrived' );
  is( $ua->seen->[0]{headers}{accept}, 'application/json', 'asks for JSON' );
  like( $ua->seen->[0]{headers}{'content-type'}, qr{\Aapplication/x-www-form-urlencoded}, 'sends a form' );

  my ( undef, $unknown ) = fixture( client_id => 'nope' );
  ok( !eval { $unknown->start; 1 }, 'an unknown client croaks' );
  like( $@, qr/start failed: invalid_client/, 'with the server error' );
};

subtest 'login: approved while polling' => sub {
  my ( $t, $client, $slept ) = fixture(
    after_sleep => sub {
      my ( $t, $polls ) = @_;
      return unless $polls == 2;
      my ( $row ) = grep { ( $_->{state} // '' ) eq 'pending' } values %{ $t->memory->_rows };
      $t->airlock->approve( $row->{user_code}, subject => { id => 'alice' } );
    }
  );
  my $token = $client->login;
  is( $token->{token_type}, 'Bearer', 'token response' );
  is( $t->airlock->verify_token( $token->{access_token} )->{subject}, 'alice', 'the token belongs to who approved' );
  is_deeply( $slept, [ 5, 5 ], 'waited the server interval before every poll, never polled without waiting' );
};

subtest 'poll: slow_down adds five seconds' => sub {
  my $calls = 0;
  my @reply = ( 'slow_down', 'authorization_pending', 'slow_down' );
  my $app   = sub {
    my $error = $reply[ $calls++ ];
    return [ 400, [ 'Content-Type' => 'application/json' ], [ encode_json( { error => $error } ) ] ] if $error;
    return [ 200, [ 'Content-Type' => 'application/json' ], [ encode_json( { access_token => 'tok', token_type => 'Bearer' } ) ] ];
  };
  my ( undef, $client, $slept ) = fixture( app => $app );
  my $token = $client->poll( { device_code => 'd', interval => 2, expires_in => 600 } );
  is( $token->{access_token}, 'tok', 'token' );
  is_deeply( $slept, [ 2, 7, 7, 12 ], 'the interval grows by five on each slow_down and stays grown' );
};

subtest 'poll: errors' => sub {
  for my $error (qw( access_denied expired_token invalid_grant )) {
    my $app = sub { [ 400, [], [ encode_json( { error => $error } ) ] ] };
    my ( undef, $client ) = fixture( app => $app );
    ok( !eval { $client->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, $error.' croaks' );
    like( $@, qr/poll failed: $error/, 'with the error' );
  }
  my ( undef, $described ) = fixture( app => sub { [ 400, [], [ encode_json( { error => 'access_denied', error_description => 'no thanks' } ) ] ] } );
  eval { $described->poll( { device_code => 'd', interval => 1, expires_in => 60 } ) };
  like( $@, qr/access_denied \(no thanks\)/, 'error_description is included' );

  my ( undef, $html ) = fixture( app => sub { [ 502, [], ['<html>Bad Gateway</html>'] ] } );
  ok( !eval { $html->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, 'a non-JSON error croaks' );
  like( $@, qr/poll failed: 502/, 'with the status' );

  my ( undef, $odd ) = fixture( app => sub { [ 200, [], ['[1,2,3]'] ] } );
  ok( !eval { $odd->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, 'JSON that is not an object croaks' );
};

subtest 'poll: errors reported with status 200' => sub {
  my @reply = ( { error => 'authorization_pending' }, { access_token => 'tok' } );
  my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( shift @reply ) ] ] } );
  is( $client->poll( { device_code => 'd', interval => 3, expires_in => 60 } )->{access_token}, 'tok', 'pending with 200 keeps polling' );
  is( scalar @$slept, 2, 'two polls' );
};

subtest 'poll: gives up when the code has expired' => sub {
  my ( undef, $client, $slept ) = fixture( app => sub { [ 400, [], [ encode_json( { error => 'authorization_pending' } ) ] ] } );
  ok( !eval { $client->poll( { device_code => 'd', interval => 5, expires_in => 12 } ); 1 }, 'croaks' );
  like( $@, qr/the code expired before anyone approved it/, 'and says why' );
  is( scalar @$slept, 3, 'after the polls that fit into the lifetime' );
};

subtest 'poll: defaults for a sparse response' => sub {
  my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( { access_token => 'tok' } ) ] ] } );
  $client->poll( { device_code => 'd' } );
  is_deeply( $slept, [5], 'interval defaults to five seconds' );
};

subtest 'discovery' => sub {
  my $config = { issuer => 'http://id.test/realms/main', device_authorization_endpoint => 'http://id.test/device', token_endpoint => 'http://id.test/token' };
  my $app    = sub { [ 200, [], [ encode_json($config) ] ] };
  my $ua     = LocalUA->new( app => $app );
  my $client = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test/realms/main/', ua => $ua );
  is( $client->device_endpoint, 'http://id.test/device', 'device endpoint' );
  is( $client->token_endpoint,  'http://id.test/token',  'token endpoint' );
  is( scalar @{ $ua->seen }, 1, 'one discovery request for both' );
  is( $ua->seen->[0]{url}, 'http://id.test/realms/main/.well-known/openid-configuration', 'at the well-known URL, without a double slash' );

  my $partial = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test', ua => LocalUA->new( app => sub { [ 200, [], ['{"issuer":"http://id.test","token_endpoint":"http://id.test/token"}'] ] } ) );
  ok( !eval { $partial->device_endpoint; 1 }, 'a server without device endpoint croaks' );
  like( $@, qr/discovery has no device_authorization_endpoint/, 'and says what is missing' );

  my $down = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test', ua => LocalUA->new( app => sub { [ 503, [], ['down'] ] } ) );
  ok( !eval { $down->token_endpoint; 1 }, 'a failed discovery croaks' );
  like( $@, qr/discovery failed: 503/, 'with the status' );

  for my $other ( 'http://evil.test/realms/main', undef, "http://id.test/realms/main\e[2J" ) {
    my $spoofed = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test/realms/main',
      ua => LocalUA->new( app => sub { [ 200, [], [ encode_json( { %$config, issuer => $other } ) ] ] } ) );
    ok( !eval { $spoofed->device_endpoint; 1 }, 'metadata for another issuer croaks' );
    like( $@, qr/discovery is for another issuer: [\x20-\x7E]+ at /, 'and names it in printable characters only' );
  }

  ok( !eval { Airlock::Client->new( client_id => 'cli' )->device_endpoint; 1 }, 'neither issuer nor endpoints croaks' );
  like( $@, qr/needs issuer, or device_endpoint and token_endpoint/, 'and says what to give' );
};

subtest 'poll: never sleeps past the lifetime of the code' => sub {
  my ( undef, $client, $slept ) = fixture( app => sub { [ 400, [], [ encode_json( { error => 'authorization_pending' } ) ] ] } );
  ok( !eval { $client->poll( { device_code => 'd', interval => 999_999_999, expires_in => 60 } ); 1 }, 'a huge interval still ends' );
  is_deeply( $slept, [60], 'after sleeping what is left of the lifetime, not the interval' );

  my @reply = ( 'slow_down', 'slow_down', 'slow_down' );
  my ( undef, $slowed, $naps ) = fixture( app => sub { [ 400, [], [ encode_json( { error => shift @reply // 'authorization_pending' } ) ] ] } );
  eval { $slowed->poll( { device_code => 'd', interval => 10, expires_in => 40 } ) };
  is_deeply( $naps, [ 10, 15, 15 ], 'the last sleep is cut to what is left' );
};

subtest 'poll: a connection failure is retried, not fatal' => sub {
  my @reply = ( [ 599, 'Timed out' ], [ 599, 'Connection refused' ], [ 200, encode_json( { access_token => 'tok' } ) ] );
  my ( undef, $client, $slept ) = fixture( app => sub { my $r = shift @reply; [ $r->[0], [], [ $r->[1] ] ] } );
  is( $client->poll( { device_code => 'd', interval => 5, expires_in => 600 } )->{access_token}, 'tok', 'the token arrives after two failures' );
  is_deeply( $slept, [ 5, 10, 15 ], 'backing off by five seconds each time' );
};

subtest 'prompt_text' => sub {
  my ( undef, $client ) = fixture();
  my $start = { verification_uri => 'https://example.org/airlock', user_code => 'BCDF-GHJK', verification_uri_complete => 'https://example.org/airlock?user_code=BCDF-GHJK' };
  my $text  = $client->prompt_text( $start, ansi => 0 );
  like( $text, qr{\AOpen https://example.org/airlock and enter the code BCDF-GHJK\nOr scan:\n}, 'where to go and the code' );
  like( $text, qr/[\x{2580}\x{2584}\x{2588}]{10}/, 'followed by the QR code' );
  is( $client->prompt_text( { verification_uri => 'https://x', user_code => 'ABCD' } ), "Open https://x and enter the code ABCD\n", 'no QR code without verification_uri_complete' );
  is( $client->prompt_text( { verification_uri => "https://x\e[2J\r", user_code => "AB\x{7}CD\n" } ), "Open https://x?[2J? and enter the code AB?CD?\n", 'control characters from the server never reach the terminal' );
};

subtest 'against a real socket' => sub {
  # the server is a process of its own, so it builds its own Airlock: the
  # in-process store refuses to be carried across a fork
  my $server = Test::TCP->new(
    code => sub {
      my ( $port ) = @_;
      HTTP::Server::PSGI->new( host => '127.0.0.1', port => $port )->run( AirlockTest->new->airlock->to_app );
    }
  );
  my $base   = 'http://127.0.0.1:'.$server->port.'/airlock';
  my $client = Airlock::Client->new( client_id => 'cli', device_endpoint => $base.'/device', token_endpoint => $base.'/token', sleep => sub { }, on_prompt => sub { } );
  my $start  = $client->start;
  like( $start->{user_code}, qr/\A\w{4}-\w{4}\z/, 'start over HTTP' );
  is( $start->{verification_uri}, 'https://example.org/airlock', 'the response is what the server sent' );
  ok( !eval { Airlock::Client->new( client_id => 'nope', device_endpoint => $base.'/device', token_endpoint => $base.'/token' )->start; 1 }, 'a refusal over HTTP croaks' );
  like( $@, qr/invalid_client/, 'with the server error' );
};

subtest 'poll: nonsense from the server does not become a busy loop' => sub {
  for my $bad ( 0, -5, 'soon', '1e9', 2.5, [], undef, '' ) {
    my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( { access_token => 'tok' } ) ] ] } );
    $client->poll( { device_code => 'd', interval => $bad, expires_in => 60 } );
    is_deeply( $slept, [5], 'interval '.( defined $bad ? ref $bad ? 'reference' : '"'.$bad.'"' : 'undef' ).' falls back to five seconds' );
  }
  for my $bad ( 0, -1, 'never', undef ) {
    my $polls = 0;
    my ( undef, $client, $slept ) = fixture( app => sub { $polls++; [ 400, [], [ encode_json( { error => 'authorization_pending' } ) ] ] } );
    ok( !eval { $client->poll( { device_code => 'd', interval => 100, expires_in => $bad } ); 1 }, 'gives up' );
    is( $polls, 6, 'expires_in '.( defined $bad ? '"'.$bad.'"' : 'undef' ).' falls back to ten minutes' );
  }
};

done_testing;
