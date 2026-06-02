use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;
use Time::HiRes ();

# immediate() getter/setter + immediate-first-run behaviour in _event().
# Default is undef (wait for interval before first callback).

# immediate() returns undef by default.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    is $e->immediate, undef, "immediate() returns undef by default";
}

# immediate(1) sets and returns the value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->immediate(1);
    is $e->immediate, 1, "immediate(1) sets and returns 1";
}

# Negative value croaks.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->immediate(-1); 1 };
    my $err = $@;
    is $ok, undef, "immediate(-1) croaks";
    like $err, qr/must be a non-negative integer/, "...with validation message";
}

# Non-numeric value croaks.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->immediate("abc"); 1 };
    my $err = $@;
    is $ok, undef, "immediate('abc') croaks";
    like $err, qr/must be a non-negative integer/, "...with validation message";
}

# Empty string croaks.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->immediate(""); 1 };
    my $err = $@;
    is $ok, undef, "immediate('') croaks";
    like $err, qr/must be a non-negative integer/, "...with validation message";
}

# Fractional seconds croak (integer-only, like timeout()).
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    my $ok = eval { $e->immediate(0.5); 1 };
    my $err = $@;
    is $ok, undef, "immediate(0.5) croaks";
    like $err, qr/must be a non-negative integer/, "...with validation message";
}

# immediate(0) disables.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->immediate(1);
    is $e->immediate, 1, "immediate set to 1";
    $e->immediate(0);
    is $e->immediate, 0, "immediate(0) disables";
}

# immediate(undef) also disables.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->immediate(1);
    is $e->immediate, 1, "immediate set to 1";
    $e->immediate(undef);
    is $e->immediate, undef, "immediate(undef) disables";
}

# immediate(1): callback fires before the first interval elapses.
# Use a 10-second interval and verify the callback runs within a short window.
{
    my $ran = 0;
    my $e = Async::Event::Interval->new(10, sub { $ran++ });
    $e->immediate(1);
    $e->start;

    my $deadline = Time::HiRes::time() + 0.5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    cmp_ok $e->runs, '>=', 1,
        "immediate(1): callback ran within 0.5s despite 10s interval";
}

# Default (no immediate): first callback does NOT fire before the interval.
# Use a 10-second interval and verify nothing runs in a short window.
{
    my $e = Async::Event::Interval->new(10, sub {});
    $e->start;

    select(undef, undef, undef, 0.25);
    $e->stop;

    is $e->runs, 0,
        "default: no callback before first interval elapses";
}

# immediate(1): subsequent invocations respect the interval after the
# immediate first run. With interval=0.05, after the immediate callback
# the second run should not happen until at least another interval.
{
    my $e = Async::Event::Interval->new(0.05, sub {});
    $e->immediate(1);
    $e->start;

    # Wait for the immediate run.
    my $deadline = Time::HiRes::time() + 0.3;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }

    my $runs_after_first = $e->runs;
    cmp_ok $runs_after_first, '>=', 1, "immediate callback ran";

    # Wait a bit more — should have additional runs from the interval loop.
    select(undef, undef, undef, 0.2);
    $e->stop;

    cmp_ok $e->runs, '>=', 2, "subsequent invocations follow interval cadence";
}

# restart() also fires immediately when immediate(1) is set.
{
    my $e = Async::Event::Interval->new(10, sub {});
    $e->immediate(1);
    $e->start;

    my $deadline = Time::HiRes::time() + 0.5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    my $runs_before = $e->runs;
    cmp_ok $runs_before, '>=', 1, "first start: immediate callback ran";

    $e->restart;

    $deadline = Time::HiRes::time() + 0.5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs > $runs_before;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    cmp_ok $e->runs, '>', $runs_before,
        "restart: immediate callback fires again on fresh child";
}

# immediate(1) with per-call params via start().
{
    use File::Temp qw(tempfile);
    my ($fh, $tmp) = tempfile(UNLINK => 1);
    my $e = Async::Event::Interval->new(10, sub {
        open my $f, '>', $tmp or die $!;
        print $f join("\n", @_);
        close $f;
    });
    $e->immediate(1);
    $e->start('a', 'b');

    my $deadline = Time::HiRes::time() + 0.5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    is $e->runs, 1, "immediate with start() params: callback ran once";
    open my $in, '<', $tmp;
    chomp(my @received = <$in>);
    close $in;
    is_deeply \@received, ['a', 'b'],
        "...received the start() params";
}

# immediate(1) with params via new() works.
{
    use File::Temp qw(tempfile);
    my ($fh, $tmp) = tempfile(UNLINK => 1);
    my $e = Async::Event::Interval->new(10, sub {
        open my $f, '>', $tmp or die $!;
        print $f join("\n", @_);
        close $f;
    }, 'x', 'y');
    $e->immediate(1);
    $e->start;

    my $deadline = Time::HiRes::time() + 0.5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    is $e->runs, 1, "immediate with new() params: callback ran once";
    open my $in, '<', $tmp;
    chomp(my @received = <$in>);
    close $in;
    is_deeply \@received, ['x', 'y'],
        "...received the new() params";
}

# info() snapshot includes the immediate value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->immediate(1);
    is $e->info->{immediate}, 1, "info() includes immediate value";
}

# events() snapshot includes the immediate value.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->immediate(1);
    my $snap = Async::Event::Interval::events();
    is $snap->{$e->id}{immediate}, 1, "events() includes immediate value";
}

# immediate(0) restores wait-for-interval behaviour.
{
    my $e = Async::Event::Interval->new(10, sub {});
    $e->immediate(1);
    $e->immediate(0);
    $e->start;

    select(undef, undef, undef, 0.25);
    $e->stop;

    is $e->runs, 0,
        "immediate(0): callback waits for first interval (not immediate)";
}
