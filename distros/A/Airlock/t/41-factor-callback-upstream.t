#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Factor::Callback;
use Airlock::Factor::Upstream;

subtest 'callback' => sub {
  my @seen;
  my $factor = Airlock::Factor::Callback->new(
    name   => 'pin',
    amr    => 'pin',
    verify => sub { push @seen, [@_]; $_[1] eq '4711' }
  );
  is( $factor->name, 'pin', 'name' );
  is( $factor->amr,  'pin', 'amr' );
  is( $factor->needs_proof, 1, 'needs a proof' );
  is( $factor->available_for( { id => 'alice' } ), 1, 'available to everyone without an available sub' );
  is( $factor->verify( { id => 'alice' }, '4711' ), 1, 'right proof' );
  is( $factor->verify( { id => 'alice' }, '0000' ), 0, 'wrong proof' );
  is_deeply( $seen[0], [ { id => 'alice' }, '4711' ], 'the sub gets subject and proof' );

  my $limited = Airlock::Factor::Callback->new(
    name      => 'pin',
    amr       => 'pin',
    verify    => sub { 1 },
    available => sub { $_[0]{id} eq 'alice' }
  );
  is( $limited->available_for( { id => 'alice' } ), 1, 'available sub: yes' );
  is( $limited->available_for( { id => 'bob' } ),   0, 'available sub: no' );

  ok( !eval { Airlock::Factor::Callback->new( name => 'pin', amr => 'pin' ); 1 }, 'verify is required' );
  ok( !eval { Airlock::Factor::Callback->new( amr => 'pin', verify => sub { 1 } ); 1 }, 'name is required' );
};

subtest 'upstream' => sub {
  my $clock  = 10_000;
  my $factor = Airlock::Factor::Upstream->new( now => sub { $clock } );
  is( $factor->name, 'upstream', 'name' );
  is( $factor->amr,  'mfa',      'amr' );
  is( $factor->needs_proof, 0, 'needs no proof' );

  is( $factor->verify( { id => 'a', amr => [qw( pwd otp )] } ), 1, 'otp in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( pwd mfa )] } ), 1, 'mfa in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( hwk )] } ),     1, 'hwk in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( pwd )] } ),     0, 'password only' );
  is( $factor->verify( { id => 'a', amr => [] } ),              0, 'empty amr' );
  is( $factor->verify( { id => 'a' } ),                         0, 'no amr at all' );
  is( $factor->verify( { id => 'a', acr => 'gold' } ),          0, 'an acr nobody configured means nothing' );

  my $acr = Airlock::Factor::Upstream->new( accept_amr => [], accept_acr => [qw( gold silver )], now => sub { $clock } );
  is( $acr->verify( { id => 'a', acr => 'gold' } ),   1, 'configured acr' );
  is( $acr->verify( { id => 'a', acr => 'bronze' } ), 0, 'other acr' );
  is( $acr->verify( { id => 'a', amr => ['otp'] } ),  0, 'amr is not accepted when the list is empty' );
  is_deeply( $acr->reauth_params, { max_age => 0, acr_values => 'gold silver' }, 'reauth params carry the acr values' );
  is_deeply( $factor->reauth_params, { max_age => 0 }, 'reauth params without acr values' );

  my $fresh = Airlock::Factor::Upstream->new( max_age => 300, now => sub { $clock } );
  # The tolerance bends one way: clock_skew widens the future edge and leaves
  # the max_age edge alone, so the window is -60..300, not -60..360. Documented
  # under Airlock::Factor::Upstream/clock_skew; these four pin it.
  is( $fresh->clock_skew, 60, 'the skew the window is built from' );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 9_700 } ), 1, 'exactly max_age old' );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 9_699 } ), 0, 'one second too old' );
  is( $fresh->verify( { id => 'a', amr => ['otp'] } ),                     0, 'no auth_time counts as too old' );
  is( $fresh->verify( { id => 'a', amr => ['pwd'], auth_time => 9_999 } ), 0, 'fresh but weak' );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 10_060 } ), 1, 'a minute in the future is clock drift' );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 10_061 } ), 0, 'further in the future is not a login' );
};

done_testing;
