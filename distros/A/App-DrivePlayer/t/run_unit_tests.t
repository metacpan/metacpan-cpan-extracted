#!/usr/bin/env perl

# Run all unit tests:
#   prove -v t/run_unit_tests.t
#
# Run a single test class:
#   TEST_CLASS=Test::DrivePlayer::DB prove -v t/run_unit_tests.t
#
# Run a single method:
#   TEST_CLASS=Test::DrivePlayer::DB TEST_METHOD=upsert_track prove -v t/run_unit_tests.t

use strict;
use warnings;

use FindBin;
use Module::Load;
use Test::Class;

use lib "$FindBin::RealBin/../lib";         # DrivePlayer source
use lib "$FindBin::RealBin/lib";            # test support
use lib "$FindBin::RealBin/unit";           # test classes

if ($ENV{TEST_CLASS}) {
    load($ENV{TEST_CLASS});
} else {
    load('Test::Class::Load');
    Test::Class::Load->import("$FindBin::RealBin/unit");
}

Test::Class->runtests();
