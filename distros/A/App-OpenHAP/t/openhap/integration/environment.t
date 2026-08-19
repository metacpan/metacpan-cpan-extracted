#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: System prerequisites and environment validation

use v5.36;
use Test::More tests => 4;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;

# The binary, configuration, user, and data-directory checks live in
# the harness: _verify_system dies in every file's setup when one is
# missing. This file keeps only what the harness does not check.

# Test 1: Environment variable set
ok($ENV{OPENHAP_INTEGRATION_TEST}, 'OPENHAP_INTEGRATION_TEST is set');

# Test 2: OpenHAP modules available
eval { require App::OpenHAP::Host; };
ok(!$@, 'App::OpenHAP::Host module available');

# Test 3: rc.d script installed
ok(-f '/etc/rc.d/openhapd', 'rc.d script installed');

# Test 4: SRP obtains the GMP Math::BigInt backend. The try => 'GMP'
# selection falls back silently to pure Perl. The pure Perl path
# reintroduces multi-minute pair-setups under TCG emulation. A
# missing backend must be a hard, visible failure here, not a
# slow-but-green run.
require Protocol::HAP::SRP;
is(Math::BigInt->config->{lib}, 'Math::BigInt::GMP',
   'Math::BigInt uses the GMP backend');
