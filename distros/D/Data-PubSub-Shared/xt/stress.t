use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use POSIX ':sys_wait_h';
use Time::HiRes 'time';

use Data::PubSub::Shared;

my $MSGS    = $ENV{STRESS_MSGS}    || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 6;
my $CAP     = 131072;
# Fail only when NO forward progress is made for this long -- a fixed
# wall-clock deadline false-fails on a starved machine and is meaningless
# on a fast one.
my $STALL   = $ENV{STRESS_STALL}   || 20;

my $total = $WORKERS * $MSGS;
my $WMUL  = 10 ** (length($MSGS) + 1);  # multiplier > MSGS for worker ID encoding
diag "stress: $WORKERS workers x $MSGS msgs each = $total total, cap=$CAP, stall=${STALL}s";

# ============================================================
# 1. MPMC Int: N publishers, 1 subscriber after — write_pos correct
# ============================================================
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, $CAP);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Int->new($path, $CAP);
            $c->publish($w * $WMUL + $_) for 1..$MSGS;
            exit 0;
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    is $ps->write_pos, $total, "mpmc int: write_pos == $total";

    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    my $expect = $total < $CAP ? $total : $CAP;
    is scalar @got, $expect, "mpmc int: drained $expect msgs";

    # verify all values are valid worker-encoded ints
    my %by_w;
    $by_w{ int($_ / $WMUL) }++ for @got;
    my @bad_workers = grep { $_ < 1 || $_ > $WORKERS } keys %by_w;
    is scalar @bad_workers, 0, "mpmc int: all messages from valid workers";

    unlink $path;
}

# ============================================================
# 2. MPMC Int: N publishers, N subscribers — live broadcast
#    Subscribers poll aggressively; verify received + overflow = total
# ============================================================
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, $CAP);

    my @sub_pids;
    for my $s (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Int->new($path, $CAP);
            my $sub = $c->subscribe;
            # Progress-based completion: accounted (received + overflow)
            # is monotonic and reaches $total once every message is
            # either delivered or counted lost.  Fail only if it stops
            # advancing for $STALL seconds -- never on a fixed deadline.
            my $received = 0;
            my $accounted = 0;
            my $last_progress = time;
            while ($accounted < $total) {
                my $v = $sub->poll_wait(1);
                if (defined $v) {
                    $received++;
                    # drain remaining without blocking
                    my @more = $sub->drain;
                    $received += @more;
                }
                my $now = $received + $sub->overflow_count;
                if ($now > $accounted) {
                    $accounted = $now;
                    $last_progress = time;
                }
                elsif (time - $last_progress > $STALL) {
                    exit 1;   # stalled: no message accounted for $STALL seconds
                }
            }
            exit 0;
        }
        push @sub_pids, $pid;
    }

    select(undef, undef, undef, 0.1);

    my @pub_pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Int->new($path, $CAP);
            my @batch = map { $w * $WMUL + $_ } 1..100;
            for (my $i = 0; $i < $MSGS; $i += 100) {
                $c->publish_multi(@batch);
            }
            exit 0;
        }
        push @pub_pids, $pid;
    }

    waitpid($_, 0) for @pub_pids;

    my $all_ok = 1;
    for my $pid (@sub_pids) {
        waitpid($pid, 0);
        $all_ok = 0 if $? != 0;
    }
    ok $all_ok, "broadcast: all $WORKERS subscribers accounted for all $total msgs";
    unlink $path;
}

# ============================================================
# 3. Str: N publishers, 1 subscriber — variable-length messages
# ============================================================
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Str->new($path, $CAP, 128);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Str->new($path, $CAP, 128);
            for my $i (1..$MSGS) {
                $c->publish(sprintf "w%d-m%d-%s", $w, $i, "x" x ($i % 50));
            }
            exit 0;
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    is $ps->write_pos, $total, "mpmc str: write_pos == $total";

    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    my $expect = $total < $CAP ? $total : $CAP;
    is scalar @got, $expect, "mpmc str: drained $expect msgs";

    my @bad = grep { $_ !~ /^w\d+-m\d+-x*$/ } @got;
    is scalar @bad, 0, "mpmc str: all messages well-formed";

    unlink $path;
}

# ============================================================
# 4. Str batch publish_multi: N publishers, concurrent
# ============================================================
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Str->new($path, $CAP, 64);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Str->new($path, $CAP, 64);
            my @batch = map { sprintf "w%d-b%d", $w, $_ } 1..50;
            for (my $i = 0; $i < $MSGS; $i += 50) {
                $c->publish_multi(@batch);
            }
            exit 0;
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    is $ps->write_pos, $total, "str batch: write_pos == $total";

    my $sub = $ps->subscribe_all;
    my $count = 0;
    $sub->poll_cb(sub { $count++ });
    my $expect = $total < $CAP ? $total : $CAP;
    is $count, $expect, "str batch: poll_cb got $expect msgs";

    unlink $path;
}

# ============================================================
# 5. Overflow recovery under pressure: small ring, fast publishers
# ============================================================
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, 256);

    my $sub = $ps->subscribe;

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = Data::PubSub::Shared::Int->new($path, 256);
            $c->publish($w * 1000 + $_) for 1..$MSGS;
            exit 0;
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    ok $sub->has_overflow, "overflow: subscriber overflowed";

    my @got = $sub->drain;
    ok scalar @got > 0, "overflow: got some messages after recovery";
    ok scalar @got <= 256, "overflow: at most capacity msgs";
    ok $sub->overflow_count > 0, "overflow: overflow_count > 0";
    diag sprintf "overflow: recovered %d msgs, lost %d", scalar @got, $sub->overflow_count;

    unlink $path;
}

# ============================================================
# 6. eventfd + fork: publisher notifies, subscriber in child
# ============================================================
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 65536);
    my $fd = $ps->eventfd;
    my $sub = $ps->subscribe;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $sub->eventfd_set($fd);
        # Progress-based: fail only if no message arrives for $STALL
        # seconds, not when a fixed deadline expires.
        my $count = 0;
        my $last_progress = time;
        while ($count < $MSGS) {
            my @msgs = $sub->drain_notify;
            if (@msgs) {
                $count += @msgs;
                $last_progress = time;
            }
            else {
                exit 1 if time - $last_progress > $STALL;
                select(undef, undef, undef, 0.001);
            }
        }
        exit 0;
    }

    select(undef, undef, undef, 0.05);
    for my $i (1..$MSGS) {
        $ps->publish($i);
        $ps->notify if $i % 100 == 0;
    }
    $ps->notify;

    waitpid($pid, 0);
    is $? >> 8, 0, "eventfd fork: child received all $MSGS msgs via drain_notify";
}

done_testing;
