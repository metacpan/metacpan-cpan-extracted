#!/usr/bin/env perl

# The device side: get a token from one of the example apps.
#
#   perl -Ilib examples/login.pl [scope ...]
#
# Against an OpenID Connect provider, pass issuer => 'https://.../realms/x'
# instead of the two endpoints and let the client discover them.

use strict;
use warnings;
use Airlock::Client;

my $base   = $ENV{AIRLOCK_EXAMPLE_URL} // 'http://localhost:5000';
my $client = Airlock::Client->new(
  client_id       => 'demo-cli',
  scope           => join( ' ', @ARGV ),
  device_endpoint => $base.'/airlock/device',
  token_endpoint  => $base.'/airlock/token'
);

my $token = $client->login;

print 'access_token: '.$token->{access_token}."\n";
print 'scope:        '.( $token->{scope} // '' )."\n";
