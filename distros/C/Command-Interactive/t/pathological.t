#!/usr/bin/perl -I ../../../lib

use strict;
use warnings;

use lib 'lib';
use Test::More (tests => 4);
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;

throws_ok(sub { Command::Interactive->new->run }, qr/No command provided/, "Must provide a command to run()",);

throws_ok(
    sub { Command::Interactive->new({debug_logfile => '/some/nonexistent/path'})->run("echo foo") },
    qr/Could not open debugging log file/,
    "Invalid log file results in expected croak",
);

my $cmd = Command::Interactive->new({
        interactions      => [Command::Interactive::Interaction->new({expected_string => 'You win!',}),],
        always_use_expect => 1,
        timeout           => 1
});
is($cmd->run("sleep 100"), "Got TIMEOUT from Expect (timeout=1 seconds)", "Capture timeout");

1;
