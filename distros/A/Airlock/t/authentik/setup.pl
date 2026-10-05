#!/usr/bin/env perl

# Builds the fixtures t/91-live-authentik.t needs in a throwaway authentik.
#
#   perl -I ~/dev/p5-www-authentik/lib t/authentik/setup.pl http://127.0.0.1:9000 API_TOKEN
#
# Unlike Keycloak, authentik needs nothing configured to report a second
# factor: a password login carries amr=pwd and a login with TOTP amr=pwd,mfa
# out of the box. So this script only creates what the test works with - an
# application with an OAuth2 provider that can do the device flow, a user with
# a password, a second user with a password, and the flow the brand needs
# before anyone can approve a device code. Enrolling the TOTP device is the
# test's own job, because it goes through the setup flow as a person would.
#
# It can be run any number of times; every call is an ensure_*.
#
# Checked against authentik 2026.8.3.

use strict;
use warnings;
use WWW::Authentik;

my ( $base, $token, $mode ) = @ARGV;
die 'usage: setup.pl AUTHENTIK_URL API_TOKEN [--remove]'."\n" unless $base && $token;

my $api = WWW::Authentik->new( base_url => $base, token => $token )->api;

if ( ( $mode // '' ) eq '--remove' ) {
  # everything this script makes, in the order that lets it go
  eval { $api->delete_application('airlock-test') } and print "removed  application airlock-test\n";
  if ( my $gone = eval { $api->find_oauth2_provider('airlock-test') } ) {
    $api->delete_oauth2_provider( $gone->{pk} );
    print "removed  provider airlock-test\n";
  }
  for my $username (qw( airlock-plain airlock-otp )) {
    my $user = eval { $api->find_user($username) } or next;
    $api->delete_user( $user->{pk} );
    print "removed  user $username\n";
  }
  my ( $brand ) = grep { $_->{default} } @{ $api->list_brands };
  my ( $flow )  = eval { $api->find_flow('airlock-test-device-code') };
  if ( $brand && $flow && ( $brand->{flow_device_code} // '' ) eq $flow->{pk} ) {
    $api->update_brand( $brand->{brand_uuid}, { flow_device_code => undef } );
    print "removed  brand ".$brand->{domain}.": flow_device_code\n";
  }
  eval { $api->delete_flow('airlock-test-device-code') } and print "removed  flow airlock-test-device-code\n";
  exit 0;
}

sub report {
  my ( $what, $result ) = @_;
  printf "%-8s %s\n", $result->{changed} || 'ok', $what;
  return $result->{object};
}

# A device flow sends the person to /device, and authentik only serves that
# page when the brand names a flow for it. An empty stage_configuration flow
# is enough: there is nothing to ask, the person is already logged in.
my $device_flow = report( 'flow airlock-test-device-code', $api->ensure_flow(
  slug        => 'airlock-test-device-code',
  name        => 'Airlock test device code',
  title       => 'Device code',
  designation => 'stage_configuration',
  authentication => 'require_authenticated'
) );

# current_brand gives the public view of the brand, which has no brand_uuid
# and so cannot be written back; the list has the whole thing
my ( $brand ) = grep { $_->{default} } @{ $api->list_brands };
( $brand ) = @{ $api->list_brands } unless $brand;
die "this authentik has no brand\n" unless $brand;
# WWW::Authentik has no ensure_brand, so this one is compared by hand
if ( ( $brand->{flow_device_code} // '' ) ne $device_flow->{pk} ) {
  $api->update_brand( $brand->{brand_uuid}, { flow_device_code => $device_flow->{pk} } );
  printf "%-8s brand %s: flow_device_code\n", 'updated', $brand->{domain};
}
else {
  printf "%-8s brand %s: flow_device_code\n", '', $brand->{domain};
}

my $provider = report( 'provider airlock-test', $api->ensure_oauth2_provider(
  name                    => 'airlock-test',
  authorization_flow_slug => 'default-provider-authorization-implicit-consent',
  invalidation_flow_slug  => 'default-provider-invalidation-flow',
  client_type             => 'public',
  # the device flow and the code exchange the test does afterwards
  grant_types             => [qw( authorization_code refresh_token urn:ietf:params:oauth:grant-type:device_code )],
  redirect_uris           => [ { matching_mode => 'strict', url => 'http://127.0.0.1:1/callback' } ],
  # offline_access so the test can see what a refresh does to auth_time
  scopes                  => [qw( openid email profile offline_access )],
  signing_key_name        => 'authentik Self-signed Certificate',
  sub_mode                => 'hashed_user_id'
) );

report( 'application airlock-test', $api->ensure_application(
  slug             => 'airlock-test',
  name             => 'Airlock test',
  provider         => $provider->{pk},
  meta_description => 'Fixture of t/91-live-authentik.t in the Airlock distribution'
) );

for my $person ( [ 'airlock-plain', 'Airlock plain' ], [ 'airlock-otp', 'Airlock with TOTP' ] ) {
  my ( $username, $name ) = @$person;
  report( 'user '.$username, $api->ensure_user(
    username => $username,
    name     => $name,
    email    => $username.'@example.org',
    password => $username.'-password'
  ) );
}

print "\nclient_id: ", $provider->{client_id}, "\n";
print "run the test with:\n";
print "  TEST_AIRLOCK_AUTHENTIK_URL=$base \\\n";
print "  TEST_AIRLOCK_AUTHENTIK_TOKEN=... \\\n";
print "  prove -lv t/91-live-authentik.t\n";
