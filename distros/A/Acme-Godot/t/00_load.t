# This is a -*- perl -*- test script for checking module use()-ability
#

use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

local $SIG{INT} = local $SIG{HUP} = sub { die "User got bored\n" };
throws_ok(
    sub {
        local $SIG{ALRM} = sub { die "Waiting no more\n" };
        alarm 5;
        require Acme::Godot;
        alarm 0;
        $SIG{ALRM} = "default";
    },
    qr/Waiting no more/,
    "Godot didn't arrive during the first 5 seconds"
);

TODO: {
    todo_skip "Need test that successfully waits for Godot to arrive", 1;

    local $SIG{INT} = local $SIG{HUP} = sub { die "not ok\n" };
    require_ok("Acme::Godot");    # FIXME: Solve halting problem
}

