use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX '_exit';
use IO::Pipe;

use Data::PubSub::Shared;

# ============================================================
# Str: publisher crashes while holding mutex
#
# Strategy: child builds a large batch, signals ready, then calls
# publish_multi (holds mutex for entire batch). Parent kills child
# mid-batch. With enough items, the window is wide enough.
#
# This test is inherently timing-dependent. If the child completes
# before the kill, recoveries=0 and we note it. If caught mid-publish,
# recoveries>=1 and recovery takes ~2s (LOCK_TIMEOUT_SEC).
# ============================================================

sub kill_mid_publish {
    my ($ps, $msg, $count) = @_;
    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my @batch = ($msg) x $count;
        # Signal parent: batch is ready, about to enter publish_multi
        print $pipe "go\n";
        $pipe->close;
        $ps->publish_multi(@batch);
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;
    sleep(0.05);
    kill 9, $pid;
    waitpid($pid, 0);
    return $pid;
}

# Test 1: single crash + recovery
{
    my $msg_size = 1024;
    my $ps = Data::PubSub::Shared::Str->new(undef, 65536, $msg_size);
    $ps->publish("before");

    my $msg = "x" x ($msg_size - 1);
    my $pid = kill_mid_publish($ps, $msg, 500000);
    diag "child $pid killed";

    my $t0 = time;
    $ps->publish("after");
    my $dt = time - $t0;

    my $stats = $ps->stats;
    diag sprintf "dt=%.2fs recoveries=%d publish_ok=%d",
        $dt, $stats->{recoveries}, $stats->{publish_ok};

    if ($stats->{recoveries} > 0) {
        ok $dt >= 1.5 && $dt < 5, sprintf('stale mutex recovery in %.2fs', $dt);
    } else {
        pass 'child completed before kill (timing-dependent)';
    }

    ok $stats->{publish_ok} >= 2, 'both pre and post-crash published';

    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    my $found = grep { $_ eq 'after' } @got;
    ok $found, 'post-crash message readable';
}

# Test 2: multiple crash cycles
{
    my $msg_size = 512;
    my $ps = Data::PubSub::Shared::Str->new(undef, 65536, $msg_size);
    my $msg = "y" x ($msg_size - 1);

    for my $round (1..3) {
        kill_mid_publish($ps, $msg, 500000);
        my $t0 = time;
        $ps->publish("round-$round");
        my $dt = time - $t0;
        ok $dt < 5, sprintf("round %d: publish in %.2fs", $round, $dt);
    }

    my $stats = $ps->stats;
    ok $stats->{publish_ok} >= 3, "multi-crash: parent messages published";
    diag sprintf "total recoveries: %d", $stats->{recoveries};
}

# Test 3: Int — no mutex, no recovery needed
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 256);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $ps->publish($_) for 1..1000;
        _exit(0);
    }
    sleep(0.01);
    kill 9, $pid;
    waitpid($pid, 0);

    my $t0 = time;
    $ps->publish(42);
    my $dt = time - $t0;

    ok $dt < 0.01, sprintf('int: no recovery delay (%.4fs)', $dt);
    ok $ps->write_pos > 0, 'int: functional after child crash';
}

done_testing;
