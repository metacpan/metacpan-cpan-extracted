#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live test against a real Keycloak. Off unless TEST_AIRLOCK_KEYCLOAK_URL is
# set to its base URL (for example http://localhost:8080), the realm from
# t/keycloak/realm.json is imported and t/keycloak/setup.pl has run against
# it. See t/keycloak/README.md.

BEGIN {
  plan skip_all => 'set TEST_AIRLOCK_KEYCLOAK_URL to run the Keycloak live test'
    unless $ENV{TEST_AIRLOCK_KEYCLOAK_URL};
  plan skip_all => 'HTTP::CookieJar is needed to log in like a browser'
    unless eval { require HTTP::CookieJar; 1 };
}

use HTTP::Tiny;
use JSON::MaybeXS;
use MIME::Base64 qw( decode_base64url );
use Airlock::Client;
use Airlock::Factor::TOTP;
use Airlock::Upstream::Keycloak;

my $base        = $ENV{TEST_AIRLOCK_KEYCLOAK_URL} =~ s{/+\z}{}r;
my $issuer      = $base.'/realms/airlock-test';
my $totp_secret = '12345678901234567890';
my $totp        = Airlock::Factor::TOTP->new( secret => sub { }, last_step => sub { }, accept_step => sub { } );

sub claims {
  my ( $jwt ) = @_;
  return decode_json( decode_base64url( ( split /\./, $jwt )[1] ) );
}

sub client {
  return Airlock::Client->new(
    issuer    => $issuer,
    client_id => 'airlock-test-cli',
    scope     => 'openid',
    sleep     => sub { sleep 1 },
    on_prompt => sub { }
  );
}

# The first form of a Keycloak page: where it posts to, its hidden fields, and
# the names of everything a person could fill in or press.
sub form {
  my ( $html ) = @_;
  my ( $action ) = $html =~ /<form[^>]*\saction="([^"]+)"/s;
  return unless $action;
  $action =~ s/&amp;/&/g;
  $action = $base.$action if $action =~ m{\A/};
  my %hidden = $html =~ /<input[^>]*type="hidden"[^>]*name="([^"]+)"[^>]*value="([^"]*)"/gs;
  my %field  = map { $_ => 1 } $html =~ /<(?:input|button)[^>]*\sname="([^"]+)"/gs;
  return { action => $action, hidden => \%hidden, field => \%field };
}

# HTTP::Tiny does not follow the redirect that answers a POST.
sub submit {
  my ( $browser, $form, %value ) = @_;
  my $response = $browser->post_form( $form->{action}, { %{ $form->{hidden} }, %value } );
  $response = $browser->get( $response->{headers}{location} )
    while $response->{status} =~ /\A30[1237]\z/ && $response->{headers}{location};
  return $response;
}

# What a person does in the browser after the device showed its code: open the
# link, log in, give the one-time code if asked, and grant the device access.
sub approve_in_browser {
  my ( $start, %login ) = @_;
  my $browser = HTTP::Tiny->new( cookie_jar => HTTP::CookieJar->new, timeout => 20 );
  my $page    = $browser->get( $start->{verification_uri_complete} );
  my $form    = form( $page->{content} ) or return 'no login form at '.$start->{verification_uri_complete};
  return 'the first page is not a login form' unless $form->{field}{username} && $form->{field}{password};
  $page = submit( $browser, $form, username => $login{username}, password => $login{password} );
  $form = form( $page->{content} ) or return 'nothing to continue with after the password';

  if ( $form->{field}{otp} ) {
    return 'Keycloak asked for a one-time code but the test has none for '.$login{username} unless $login{totp};
    # Keycloak takes a code once. If an earlier run used this time step, the
    # form comes back; then wait for the next step and try once more.
    for my $attempt ( 1, 2 ) {
      $page = submit( $browser, $form, otp => $totp->code_at( $login{totp}, int( time / 30 ) ) );
      $form = form( $page->{content} ) or return 'nothing to continue with after the one-time code';
      last unless $form->{field}{otp};
      return 'the one-time code was refused twice' if $attempt == 2;
      sleep 31 - time % 30;
    }
  }
  return 'no consent page, got a form with: '.join( ' ', sort keys %{ $form->{field} } ) unless $form->{field}{accept};
  submit( $browser, $form, accept => 'Yes' );
  return '';
}

subtest 'discovery and a poll nobody answers' => sub {
  my $client = client();
  like( $client->device_endpoint, qr{\Ahttp}, 'discovery finds the device authorization endpoint' );
  my $start = $client->start;
  ok( length $start->{device_code}, 'device_code' );
  ok( length $start->{user_code},   'user_code' );
  like( $start->{verification_uri_complete}, qr{\Ahttp.+\Q$start->{user_code}\E}, 'verification_uri_complete carries the code' );

  # A poll that outlives a short deadline proves Keycloak answered
  # authorization_pending the way the client expects; any other answer would
  # croak with "poll failed".
  ok( !eval { $client->poll( { %$start, interval => 1, expires_in => 3 } ); 1 }, 'polling without approval ends' );
  like( $@, qr/the code expired before anyone approved it/, 'because the code ran out, not because of an unexpected answer' );
};

my %subject;

for my $case (
  { name => 'password only',     username => 'plain', password => 'plain-password', amr => ['pwd'] },
  { name => 'password and TOTP', username => 'otp',   password => 'otp-password',   amr => [qw( pwd otp )], totp => $totp_secret }
  )
{
  subtest 'the whole device flow, logging in with '.$case->{name} => sub {
    my $client = client();
    my $start  = $client->start;
    my $before = time;
    is( approve_in_browser( $start, %$case ), '', 'a person logs in and grants the device access' ) or return;
    my $token = eval { $client->poll( { %$start, interval => 1, expires_in => 20 } ) };
    ok( $token && $token->{access_token}, 'the client gets its token' ) or return diag $@;

    my $claims = claims( $token->{id_token} );
    diag $case->{username}.': acr='.( $claims->{acr} // '(none)' ).' amr='.join( ',', @{ $claims->{amr} || [] } ).' auth_time='.( $claims->{auth_time} // '(none)' );
    is( $claims->{preferred_username}, $case->{username}, 'for the person who logged in' );
    is_deeply( $claims->{amr}, $case->{amr}, 'amr says how' )
      or diag 'no amr usually means t/keycloak/setup.pl has not run against this Keycloak';
    cmp_ok( $claims->{auth_time} // 0, '>=', $before - 60, 'auth_time is the login just made' );
    is_deeply( claims( $token->{access_token} )->{amr}, $case->{amr}, 'the access token says the same' );
    $subject{ $case->{username} } = Airlock::Upstream::Keycloak->new->subject($claims);
  };
}

subtest 'the upstream factor on real Keycloak claims' => sub {
  plan skip_all => 'needs both logins' unless $subject{plain} && $subject{otp};
  my $factor = Airlock::Upstream::Keycloak->new->factor( max_age => 300 );
  isnt( $subject{plain}{id}, $subject{otp}{id}, 'two people, two ids' );
  is( $factor->verify( $subject{plain} ), 0, 'a password login does not hold' );
  is( $factor->verify( $subject{otp} ),   1, 'a login with TOTP does' );
  my $stale = Airlock::Upstream::Keycloak->new->factor( max_age => 300, now => sub { time + 400 } );
  is( $stale->verify( $subject{otp} ), 0, 'but not once it is older than max_age' );
};

done_testing;
