use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;

# timeout() getter/setter + per-callback alarm wrapping in
# _run_callback(). Default is undef (no timeout). Set a positive
# integer to have the callback self-terminate if it exceeds the limit.

# timeout() returns undef by default.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    is $e->timeout, undef, "timeout() returns undef by default";
}

# timeout(5) sets and returns the value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->timeout(5);
    is $e->timeout, 5, "timeout(5) sets and returns 5";
}

# Negative value croaks.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->timeout(-1); 1 };
    my $err = $@;
    is $ok, undef, "timeout(-1) croaks";
    like $err, qr/must be a non-negative integer/, "...with validation message";
}

# Non-numeric value croaks.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->timeout("abc"); 1 };
    my $err = $@;
    is $ok, undef, "timeout('abc') croaks";
    like $err, qr/must be a non-negative integer/,
        "...with validation message";
}

# Fractional seconds croak (integer-only by design; CORE::alarm()
# silently ignores sub-second values on macOS 26 / Perl 5.36).
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->timeout(0.5); 1 };
    my $err = $@;
    is $ok, undef, "timeout(0.5) croaks";
    like $err, qr/must be a non-negative integer/,
        "...with validation message";
}

# Empty string croaks (only undef or a non-negative integer are valid).
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->timeout(""); 1 };
    my $err = $@;
    is $ok, undef, "timeout('') croaks";
    like $err, qr/must be a non-negative integer/,
        "...with validation message";
}

# timeout(0) disables the timeout.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->timeout(5);
    is $e->timeout, 5, "timeout set to 5";
    $e->timeout(0);
    is $e->timeout, 0, "timeout(0) disables";
}

# timeout(undef) also disables.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->timeout(5);
    is $e->timeout, 5, "timeout set to 5";
    $e->timeout(undef);
    is $e->timeout, undef, "timeout(undef) disables";
}

# Run-once: callback completes under timeout, no error.
{
    my $e = Async::Event::Interval->new(0, sub {});
    $e->timeout(2);
    $e->start;
    select(undef, undef, undef, 0.25);
    is $e->runs,  1, "run-once under timeout: callback ran";
    is $e->errors, 0, "run-once under timeout: no errors";
}

# Run-once: callback exceeds timeout, error recorded.
{
    my $e = Async::Event::Interval->new(0, sub {
        select(undef, undef, undef, 5);
    });
    $e->timeout(1);
    $e->start;
    select(undef, undef, undef, 2);
    is $e->errors, 1, "run-once over timeout: errors incremented";
    like $e->error_message, qr/Callback timed out after 1 second/,
        "run-once over timeout: error_message records timeout";
}

# Interval mode: callback completes under timeout, multiple iterations.
{
    my $count = 0;
    my $e = Async::Event::Interval->new(0.1, sub { $count++ });
    $e->timeout(2);
    $e->start;
    select(undef, undef, undef, 0.5);
    $e->stop;
    cmp_ok $e->runs, '>=', 2, "interval under timeout: ran at least twice";
    is $e->errors, 0, "interval under timeout: no errors";
}

# Interval mode: callback exceeds timeout, child exits with error.
# A timeout in interval mode terminates the whole loop (the child dies
# via _pm->finish(1), same as any other crash); the user must restart()
# to resume. This pins down that design choice.
{
    my $e = Async::Event::Interval->new(0.1, sub {
        select(undef, undef, undef, 5);
    });
    $e->timeout(1);
    $e->start;
    select(undef, undef, undef, 2);
    is $e->errors, 1, "interval over timeout: errors incremented";
    like $e->error_message, qr/Callback timed out after 1 second/,
        "interval over timeout: error_message records timeout";
    is $e->status, 0,
        "interval over timeout: status() is 0 (child no longer running)";
    is $e->error, 1,
        "interval over timeout: error() is 1 (event needs restart)";
    is $e->pid, undef,
        "interval over timeout: pid() cleared by _detect_crash";
}

# Changing timeout() mid-stream takes effect on the next iteration.
# _run_callback reads $self->timeout from shared %events on each entry,
# so a setter call in the parent is visible to the child's next call.
{
    my $e = Async::Event::Interval->new(0.1, sub {
        select(undef, undef, undef, 2);
    });
    $e->timeout(5);                          # generous, 2s callback completes
    $e->start;
    my $waited = 0;
    until ($e->runs >= 1 || $waited >= 10) {
        select(undef, undef, undef, 0.1);
        $waited += 0.1;
    }
    is $e->errors, 0,
        "dynamic timeout: no errors under generous initial timeout";
    cmp_ok $e->runs, '>=', 1,
        "dynamic timeout: at least one iteration completed";

    $e->timeout(1);                          # shorten below callback runtime
    select(undef, undef, undef, 3.5);        # next iteration starts & fires
    is $e->errors, 1,
        "dynamic timeout: error recorded after timeout was shortened";
    like $e->error_message, qr/timed out after 1 second/,
        "dynamic timeout: error_message reflects the new timeout";
}

# info() snapshot includes the timeout value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->timeout(30);
    is $e->info->{timeout}, 30, "info() includes timeout value";
}

# events() snapshot includes the timeout value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->timeout(15);
    my $snap = Async::Event::Interval::events();
    is $snap->{$e->id}{timeout}, 15, "events() includes timeout value";
}

# Timeout persists across restart.
{
    my $e = Async::Event::Interval->new(0, sub {
        select(undef, undef, undef, 5);
    });
    $e->timeout(1);
    $e->start;
    select(undef, undef, undef, 2);
    is $e->errors, 1, "first run timed out";

    $e->error;  # trigger _detect_crash so _started is cleared

    $e->restart;
    select(undef, undef, undef, 2);
    is $e->errors, 2, "second run also timed out (timeout persisted)";
    like $e->error_message, qr/timed out after 1 second/,
        "error_message still matches timeout pattern after restart";
}
