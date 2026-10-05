#!/usr/bin/env perl

# Makes the test realm report how someone logged in.
#
#   perl -I ~/dev/p5-www-keycloak/lib t/keycloak/setup.pl http://localhost:8080 [admin-user] [admin-password]
#
# Keycloak only puts an "amr" claim into a token when the client has the AMR
# protocol mapper and the steps of the authentication flows carry a reference
# value. The mapper is in realm.json; the reference values cannot be imported
# without spelling out every built-in flow, so this script sets both through
# the Admin REST API with WWW::Keycloak. It can be run any number of times.
#
# Checked against Keycloak 26.8.0.

use strict;
use warnings;
use WWW::Keycloak;

my ( $base, $user, $password ) = @ARGV;
die 'usage: setup.pl KEYCLOAK_URL [admin-user] [admin-password]'."\n" unless $base;

my $admin = WWW::Keycloak->new(
  base_url => $base,
  realm    => 'airlock-test',
  username => $user // 'admin',
  password => $password // 'admin'
)->admin;

# how long, in seconds, a passed step counts towards amr
my $max_age = 3600;

sub report {
  my ( $what, $result ) = @_;
  printf "%-8s %s\n", $result->{changed} || 'ok', $what;
  return;
}

report( 'client airlock-test-cli: AMR mapper', $admin->ensure_protocol_mapper(
  client         => 'airlock-test-cli',
  name           => 'amr',
  protocolMapper => 'oidc-amr-mapper',
  config         => { map { $_ => 'true' } qw( id.token.claim access.token.claim introspection.token.claim userinfo.token.claim ) }
) );

for my $step (
  [ 'browser',      'auth-username-password-form',    'pwd' ],
  [ 'browser',      'auth-otp-form',                  'otp' ],
  [ 'direct grant', 'direct-grant-validate-password', 'pwd' ],
  [ 'direct grant', 'direct-grant-validate-otp',      'otp' ]
  )
{
  my ( $flow, $authenticator, $amr ) = @$step;
  report( $flow.' / '.$authenticator.' => '.$amr, $admin->ensure_execution_config(
    flow          => $flow,
    authenticator => $authenticator,
    alias         => 'amr '.$flow.' '.$authenticator,
    config        => { 'default.reference.value' => $amr, 'default.reference.maxAge' => $max_age }
  ) );
}
