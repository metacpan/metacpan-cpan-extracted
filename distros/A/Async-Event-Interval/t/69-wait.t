use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;
use Time::HiRes ();

use Async::Event::Interval;

# Tests for wait(): blocks until the event is dormant, with an optional
# polling interval.

my $mod = 'Async::Event::Interval';

# 1. wait() blocks until a one-shot event finishes.
{
    my $e = $mod->new(0, sub { select(undef, undef, undef, 0.1) });
    $e->start;

    my $start = Time::HiRes::time();
    $e->wait;
    my $elapsed = Time::HiRes::time() - $start;

    ok $e->waiting, "wait(): event is dormant after wait() returns";
    cmp_ok $elapsed, '>=', 0.05,
        "wait(): blocked for approximately the callback duration (elapsed=$elapsed)";
}

# 2. wait() returns immediately when the event is already dormant.
{
    my $e = $mod->new(0, sub {});

    my $start = Time::HiRes::time();
    $e->wait;
    my $elapsed = Time::HiRes::time() - $start;

    cmp_ok $elapsed, '<', 0.05,
        "wait(): returns immediately when already dormant (elapsed=$elapsed)";
}

# 3. wait() returns after a callback crash; error flag is set on return.
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;

    $e->wait;

    ok $e->error,   "wait(): returns after callback crash and error flag is set";
    ok $e->waiting, "wait(): event is dormant after crash";
}

# 4. wait() accepts a custom polling interval and still blocks for the
#    full callback duration.
{
    my $e = $mod->new(0, sub { select(undef, undef, undef, 0.05) });
    $e->start;

    my $start = Time::HiRes::time();
    $e->wait(0.001);
    my $elapsed = Time::HiRes::time() - $start;

    ok $e->waiting, "wait(\$interval): completes with a custom poll interval";
    cmp_ok $elapsed, '>=', 0.03,
        "wait(\$interval): respects callback duration (elapsed=$elapsed)";
}

# 5. wait() croaks on a non-numeric interval argument.
{
    my $e = $mod->new(0, sub {});
    eval { $e->wait('abc') };
    like $@, qr/integer or float/, "wait(): croaks on non-numeric interval";
}

# 6. wait() with integer interval is accepted.
{
    my $e = $mod->new(0, sub {});
    eval { $e->wait(1) };
    is $@, '', "wait(): accepts integer interval without croaking";
}
