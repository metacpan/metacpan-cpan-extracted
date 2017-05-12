#!/usr/bin/perl -I../../../lib

use strict;
use warnings;

use lib 'lib';
use File::Temp ();
use IO::File;
use Test::More (tests => 3);
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;

# Test 1. Create a simple expected interaction
# and verify that it works "echo yes"
my $interaction = Command::Interactive::Interaction->new({
        expected_string          => '(north|south)',
        is_required              => 1,
        expected_string_is_regex => 1,
});

my $command = Command::Interactive->new({interactions => [$interaction],});

is($command->run("echo north"), undef, "Regex capture works");
is($command->run("echo east"), "Failed to encounter required regex '(north|south)' before exit", "Detect absence of required regex match");
