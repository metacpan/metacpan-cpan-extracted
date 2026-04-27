use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::PubSub::Shared;

# Multiple concurrent Int publishers
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, 4096);

    my $n_publishers = 3;
    my $msgs_per = 100;
    my @pids;

    for my $p (1..$n_publishers) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::PubSub::Shared::Int->new($path, 4096);
            for my $i (1..$msgs_per) {
                $child->publish($p * 1000 + $i);
            }
            exit 0;
        }
        push @pids, $pid;
    }

    waitpid($_, 0) for @pids;

    is $ps->write_pos, $n_publishers * $msgs_per,
        'multi-publisher: all messages published';

    my $sub = $ps->subscribe_all;
    my @got = $sub->drain;
    is scalar @got, $n_publishers * $msgs_per,
        'multi-publisher: subscriber gets all messages';

    # Verify each publisher's messages are present
    my %by_pub;
    for my $v (@got) {
        my $pub = int($v / 1000);
        push @{$by_pub{$pub}}, $v % 1000;
    }
    for my $p (1..$n_publishers) {
        is scalar @{$by_pub{$p}}, $msgs_per,
            "multi-publisher: publisher $p sent $msgs_per msgs";
        # Check per-publisher ordering (fetch_add preserves per-publisher order)
        my @sorted = sort { $a <=> $b } @{$by_pub{$p}};
        is_deeply \@sorted, [1..$msgs_per],
            "multi-publisher: publisher $p values complete";
    }
    unlink $path;
}

# eventfd_set after fork
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $fd = $ps->eventfd;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child inherits the eventfd via fork
        $ps->eventfd_set($fd);
        $ps->publish(77);
        $ps->notify;
        exit 0;
    }

    waitpid($pid, 0);
    $ps->eventfd_consume;
    my $sub = $ps->subscribe_all;
    is $sub->poll, 77, 'eventfd_set after fork: child notification received';
}

# Concurrent Str publisher + subscriber
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Str->new($path, 256, 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $child = Data::PubSub::Shared::Str->new($path, 256, 64);
        my $sub = $child->subscribe;
        my $count = 0;
        for (1..50) {
            my $v = $sub->poll_wait(30);
            $count++ if defined $v;
        }
        exit($count == 50 ? 0 : 1);
    }

    select(undef, undef, undef, 0.5);
    for my $i (1..50) {
        $ps->publish("concurrent-$i");
    }

    waitpid($pid, 0);
    is $? >> 8, 0, 'concurrent str publisher+subscriber: child got all 50';
    unlink $path;
}

done_testing;
