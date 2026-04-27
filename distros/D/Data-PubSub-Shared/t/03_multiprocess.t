use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use POSIX ':sys_wait_h';

use Data::PubSub::Shared;

# Int: publisher in parent, subscriber in child
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, 256);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child: subscribe and collect
        my $child_ps = Data::PubSub::Shared::Int->new($path, 256);
        my $sub = $child_ps->subscribe;
        my @got;
        for (1..5) {
            my $v = $sub->poll_wait(30);
            push @got, $v if defined $v;
        }
        # Signal success via exit code
        exit(scalar @got == 5 ? 0 : 1);
    }

    # Parent: publish
    select(undef, undef, undef, 0.5);  # let child subscribe
    $ps->publish($_) for 1..5;
    waitpid($pid, 0);
    is $? >> 8, 0, 'child received all 5 int messages';
    unlink $path;
}

# Str: publisher in parent, subscriber in child
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Str->new($path, 256);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $child_ps = Data::PubSub::Shared::Str->new($path, 256);
        my $sub = $child_ps->subscribe;
        my @got;
        for (1..3) {
            my $v = $sub->poll_wait(30);
            push @got, $v if defined $v;
        }
        exit(join(',', @got) eq 'foo,bar,baz' ? 0 : 1);
    }

    select(undef, undef, undef, 0.5);
    $ps->publish("foo");
    $ps->publish("bar");
    $ps->publish("baz");
    waitpid($pid, 0);
    is $? >> 8, 0, 'child received all str messages';
    unlink $path;
}

# Multiple subscribers across processes
{
    my $path = tmpnam();
    my $ps = Data::PubSub::Shared::Int->new($path, 256);

    my @pids;
    for my $i (1..3) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child_ps = Data::PubSub::Shared::Int->new($path, 256);
            my $sub = $child_ps->subscribe;
            my $v = $sub->poll_wait(30);
            exit(defined $v && $v == 42 ? 0 : 1);
        }
        push @pids, $pid;
    }

    select(undef, undef, undef, 0.5);
    $ps->publish(42);

    my $all_ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $all_ok = 0 if $? != 0;
    }
    ok $all_ok, '3 child subscribers all received same message';
    unlink $path;
}

# Anonymous pubsub via fork
{
    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $sub = $ps->subscribe;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        $ps->publish(999);
        exit 0;
    }

    waitpid($pid, 0);
    my $v = $sub->poll;
    is $v, 999, 'anonymous pubsub works across fork';
}

done_testing;
