#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use AirlockTest;

sub token {
  my ( $t ) = @_;
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice' } );
  return $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
}

subtest 'verify_token' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  ok( $t->airlock->verify_token($token), 'a fresh token verifies' );
  is( $t->memory->find( 'hash', $token ), undef, 'the store does not hold the token itself' );
  is( $t->airlock->verify_token( 'f' x 64 ), undef, 'unknown token' );
  is( $t->airlock->verify_token(''),         undef, 'empty' );
  is( $t->airlock->verify_token(undef),      undef, 'undef' );
  $t->advance(3599);
  ok( $t->airlock->verify_token($token), 'one second before expiry' );
  $t->advance(1);
  is( $t->airlock->verify_token($token), undef, 'at expiry' );
};

subtest 'a device code is not a token and a token is not a device code' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  is( $t->airlock->verify_token( $data->{device_code} ), undef, 'device code as token' );
  my $token = token($t);
  is( $t->airlock->redeem( device_code => $token, client_id => 'cli' )->status, 'invalid_grant', 'token as device code' );
};

subtest 'revoke_token' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  is( $t->airlock->revoke_token($token), 1, 'revoked' );
  is( $t->airlock->verify_token($token), undef, 'no longer verifies' );
  is( $t->airlock->revoke_token($token), 0, 'revoking twice reports nothing to revoke' );
  is( $t->airlock->revoke_token('nope'), 0, 'unknown token' );
  is( $t->airlock->revoke_token(undef),  0, 'undef' );
};

subtest 'token_ttl' => sub {
  my $t = AirlockTest->new( token_ttl => 60 );
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice' } );
  my $response = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data;
  is( $response->{expires_in}, 60, 'expires_in follows token_ttl' );
  $t->advance(60);
  is( $t->airlock->verify_token( $response->{access_token} ), undef, 'and so does expiry' );
};

subtest 'purge' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  my $open  = $t->start;
  is( $t->airlock->purge, 0, 'nothing has expired yet' );
  $t->advance(601);
  is( $t->airlock->purge, 2, 'the redeemed and the abandoned request go' );
  ok( $t->airlock->verify_token($token), 'the token stays' );
  $t->advance(3600);
  is( $t->airlock->purge, 1, 'until it has expired too' );

  my $bare = AirlockTest->new;
  delete $bare->airlock->store->{purge};
  is( $bare->airlock->purge, 0, 'a store without purge is fine' );
};

done_testing;
