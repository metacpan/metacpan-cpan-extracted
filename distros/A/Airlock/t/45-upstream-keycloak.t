#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Upstream::Keycloak;

my $keycloak = Airlock::Upstream::Keycloak->new;

subtest 'subject' => sub {
  is_deeply(
    $keycloak->subject( { sub => 'f:1234:alice', amr => [qw( pwd otp )], acr => '1', auth_time => 1700000000, email => 'a@example.org' } ),
    { id => 'f:1234:alice', amr => [qw( pwd otp )], acr => '1', auth_time => 1700000000 },
    'sub, amr, acr and auth_time are taken, nothing else'
  );
  is_deeply( $keycloak->subject( { sub => 'x' } ), { id => 'x', amr => [], acr => undef, auth_time => undef }, 'a token without the optional claims' );
  is_deeply( $keycloak->subject( { sub => 'x', amr => 'pwd otp' } )->{amr}, [qw( pwd otp )], 'amr as a string is split' );
  my $claims = { sub => 'x', amr => ['pwd'] };
  push @{ $keycloak->subject($claims)->{amr} }, 'otp';
  is_deeply( $claims->{amr}, ['pwd'], 'the claims are not modified through the subject' );
  for my $bad ( undef, {}, { sub => '' }, 'x' ) {
    ok( !eval { $keycloak->subject($bad); 1 }, 'claims without sub croak' );
  }
};

subtest 'factor' => sub {
  my $factor = $keycloak->factor( max_age => 300, now => sub { 1000 } );
  isa_ok( $factor, 'Airlock::Factor::Upstream' );
  is( $factor->name, 'upstream', 'name' );
  is( $factor->max_age, 300, 'options are passed on' );
  is( $factor->verify( $keycloak->subject( { sub => 'x', amr => ['otp'], auth_time => 900 } ) ), 1, 'holds for a login with a second factor' );
  is( $factor->verify( $keycloak->subject( { sub => 'x', amr => ['pwd'], auth_time => 900 } ) ), 0, 'not for a password login' );

  my $by_acr = Airlock::Upstream::Keycloak->new( mfa_amr => [], mfa_acr => ['2'] )->factor;
  is( $by_acr->verify( { id => 'x', acr => '2' } ), 1, 'mfa_acr configures the factor' );
  is( $by_acr->verify( { id => 'x', acr => '1', amr => ['otp'] } ), 0, 'and mfa_amr can be emptied' );
};

done_testing;
