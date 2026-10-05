#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Upstream::Authentik;

my $authentik = Airlock::Upstream::Authentik->new;

# what authentik 2026.8.3 really sends, from t/authentik/README.md
my $acr = 'goauthentik.io/providers/oauth2/default';

subtest 'subject' => sub {
  is_deeply(
    $authentik->subject( { sub => '60f3643792ea', amr => [qw( pwd mfa )], acr => $acr, auth_time => 1700000000,
      email => 'a@example.org', sid => 'abc' } ),
    { id => '60f3643792ea', amr => [qw( pwd mfa )], acr => $acr, auth_time => 1700000000 },
    'sub, amr, acr and auth_time are taken, nothing else'
  );
  is_deeply( $authentik->subject( { sub => 'x' } ), { id => 'x', amr => [], acr => undef, auth_time => undef },
    'a token without the optional claims' );
  is_deeply( $authentik->subject( { sub => 'x', amr => 'pwd mfa' } )->{amr}, [qw( pwd mfa )], 'amr as a string is split' );
  my $claims = { sub => 'x', amr => ['pwd'] };
  push @{ $authentik->subject($claims)->{amr} }, 'mfa';
  is_deeply( $claims->{amr}, ['pwd'], 'the claims are not modified through the subject' );
  for my $bad ( undef, {}, { sub => '' }, 'x' ) {
    ok( !eval { $authentik->subject($bad); 1 }, 'claims without sub croak' );
  }
};

subtest 'factor' => sub {
  my $factor = $authentik->factor( max_age => 300, now => sub { 1000 } );
  isa_ok( $factor, 'Airlock::Factor::Upstream' );
  is( $factor->name, 'upstream', 'name' );
  is( $factor->max_age, 300, 'options are passed on' );

  # authentik writes mfa, and needs nothing configured to do it
  is( $factor->verify( $authentik->subject( { sub => 'x', amr => [qw( pwd mfa )], acr => $acr, auth_time => 900 } ) ),
    1, 'holds for a login with a second factor' );
  is( $factor->verify( $authentik->subject( { sub => 'x', amr => ['pwd'], acr => $acr, auth_time => 900 } ) ),
    0, 'not for a password login' );

  # the one acr authentik sends says nothing, so it must not decide anything
  is( $factor->verify( { id => 'x', acr => $acr } ), 0, 'the constant acr alone is not a second factor' );
  is_deeply( $authentik->mfa_acr, [], 'and mfa_acr is empty by default' );
  my $by_acr = Airlock::Upstream::Authentik->new( mfa_amr => [], mfa_acr => ['high'] )->factor;
  is( $by_acr->verify( { id => 'x', acr => 'high' } ), 1, 'mfa_acr still configures the factor' );
  is( $by_acr->verify( { id => 'x', acr => $acr, amr => ['mfa'] } ), 0, 'and mfa_amr can be emptied' );
};

subtest 'max_age against an old session with a fresh token' => sub {
  # authentik's auth_time is when the session began and stays put while new
  # tokens are minted from it, so max_age measures the age of the
  # authentication, which is what a caller wants
  my $login = 1000;
  my $claims = sub {
    my ( $minted ) = @_;
    return { sub => 'x', amr => [qw( pwd mfa )], acr => $acr, auth_time => $login, iat => $minted };
  };
  my $fresh = Airlock::Upstream::Authentik->new->factor( max_age => 300, now => sub { $login + 60 } );
  is( $fresh->verify( $authentik->subject( $claims->( $login + 60 ) ) ), 1, 'a minute after the login it holds' );

  my $stale = Airlock::Upstream::Authentik->new->factor( max_age => 300, now => sub { $login + 600 } );
  is( $stale->verify( $authentik->subject( $claims->( $login + 600 ) ) ), 0,
    'ten minutes later it does not, although the token was minted just now' );

  # without auth_time there is nothing to measure, and a factor with max_age
  # must not hold on faith
  is( $fresh->verify( { id => 'x', amr => ['mfa'] } ), 0, 'and not at all without auth_time' );
};

subtest 'sending someone back for a fresh login' => sub {
  # the shared factor offers the OIDC standard, which is the one value
  # authentik throws away, so the upstream has its own
  is_deeply( $authentik->factor->reauth_params, { max_age => 0 },
    'the factor still offers max_age => 0, as every other provider wants it' );

  is_deeply( $authentik->reauth_params, { prompt => 'login' },
    'the upstream offers prompt=login, which authentik honours' );
  is_deeply( $authentik->reauth_params( max_age => 300 ), { max_age => 300 },
    'or a max_age that is not zero' );
  is_deeply( Airlock::Upstream::Authentik->new( mfa_acr => [ 'a', 'b' ] )->reauth_params,
    { prompt => 'login', acr_values => 'a b' }, 'with acr_values when there are any' );

  ok( !eval { $authentik->reauth_params( max_age => 0 ); 1 }, 'a max_age of 0 is refused' );
  like( $@, qr/authentik ignores it/, 'and says why' );
  is_deeply( $authentik->reauth_params( max_age => undef ), { prompt => 'login' },
    'an undef max_age is the same as leaving it out' );
};

done_testing;
