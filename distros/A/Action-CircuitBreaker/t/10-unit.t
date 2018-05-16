use Action::CircuitBreaker;

use strict;
use warnings;

use Test::More;

use Try::Tiny;

{
    my $var = 0;
    my $action = Action::CircuitBreaker->new();
    for my $x (0 .. 10) {
        try {
            $action->run(sub { $var++; die "plop" });
        } catch {
            # That's OK
        };
    }

    is($var, 10, "expected 10 tries to be run");
}

{
    my $opened = 0;
    my $action = Action::CircuitBreaker->new(
        on_circuit_open => sub { $opened++; },
    );
    for my $x (0 .. 10) {
        try {
            $action->run(sub { die "plop" });
        } catch {
            # That's OK
        };
    }

    is($opened, 1, "expected circuit to be opened once");
}

{
    my $closed = 0;
    my $action = Action::CircuitBreaker->new(
        on_circuit_close => sub { $closed++; },
        open_time => 1,
    );
    for my $x (0 .. 10) {
        try {
            $action->run(sub { die "plop" });
        } catch {
            # That's OK
        };
    }

    sleep(2);
    
    my $actual = $action->run(sub { return 42 });

    is($closed, 1, "expected circuit to be closed once");
    is($actual, 42, "expected original value to be returned");
}

{
    my $action = Action::CircuitBreaker->new();
    my $actual = $action->run(sub { return 42; });
    is($actual, 42, "expected original value to be returned");
}

done_testing;
