#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Airlock
  Airlock::Client
  Airlock::Code
  Airlock::Factor
  Airlock::Factor::Callback
  Airlock::Factor::TOTP
  Airlock::Factor::Upstream
  Airlock::HTTPMessage
  Airlock::Policy
  Airlock::QR
  Airlock::Result
  Airlock::Role::Endpoints
  Airlock::Store::Memory
  Airlock::Test::Store
  Airlock::Upstream::Authentik
  Airlock::Upstream::Keycloak
)) {
  use_ok($_);
}

done_testing;
