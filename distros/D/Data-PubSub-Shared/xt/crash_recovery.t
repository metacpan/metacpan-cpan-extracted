use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX qw(_exit WUNTRACED);
use Data::PubSub::Shared;

sub kill_mid_publish {
    my ($ps, $msg) = @_;
    pipe my $reader, my $ready or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $reader;
        my @batch = ($msg) x 8192;
        print {$ready} "go\n";
        close $ready;
        $ps->publish_multi(@batch) while 1;
        _exit(0);
    }
    close $ready;
    <$reader>;
    close $reader;
    open my $fd, '+<&', $ps->memfd or die "dup: $!";
    my $held = 0;
    for (1..100) {
        kill 'STOP', $pid;
        waitpid($pid, WUNTRACED);
        sysseek($fd, 72, 0) // die "seek: $!";
        sysread($fd, my $word, 4) == 4 or die "read: $!";
        $held = unpack('L', $word) == ($pid | 0x80000000);
        last if $held;
        kill 'CONT', $pid;
        sleep 0.002;
    }
    close $fd;
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return $held;
}

for my $size (512, 1024) {
    my $ps = Data::PubSub::Shared::Str->new_memfd('crash-recovery', 32768, $size);
    for my $round (1..2) {
        ok kill_mid_publish($ps, 'x' x $size), "size $size round $round: killed the lock owner";
        my $start = time;
        $ps->publish("after-$round");
        cmp_ok time - $start, '<', 8, 'stale lock recovery is bounded';
        is $ps->stats->{recoveries}, $round, 'each abandoned lock was recovered';
        my @got = $ps->subscribe_all->drain;
        is $got[-1], "after-$round", 'post-crash message is readable';
    }
}

{
    my $ps = Data::PubSub::Shared::Int->new(undef, 256);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $ps->publish($_) for 1..1000;
        _exit(0);
    }
    sleep 0.01;
    kill 'KILL', $pid;
    waitpid($pid, 0);
    $ps->publish(42);
    my $sub = $ps->subscribe;
    $sub->cursor($ps->write_pos - 1);
    is $sub->poll, 42, 'integer publish remains readable after a publisher exits';
}

done_testing;
