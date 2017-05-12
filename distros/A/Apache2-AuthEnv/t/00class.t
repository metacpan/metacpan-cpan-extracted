#!perl

# Test module.

use 5;
use warnings;
use strict;

use Test::More tests => 2;

# Provide these.
BEGIN {$ENV{MOD_PERL_API_VERSION} = 2; }
sub Apache2::Module::add {};

# Tests
use_ok('Apache2::AuthEnv');

my $c;
ok( $c = new Apache2::AuthEnv, 'constructor');


