use strict;
use warnings;
use Test::More;
use IO::Select;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Queue::Shared;

my @children;
my $parent = $$;
END {
    if ($$ == $parent) {
        kill 'KILL', @children if @children;
        waitpid($_, 0) for @children;
    }
}

my @removals = (
    [pop => sub { $_[0]->pop }, 0],
    [pop_back => sub { $_[0]->pop_back }, 1],
    [pop_multi => sub { $_[0]->pop_multi(1) }, 0],
    [drain => sub { $_[0]->drain(1) }, 0],
    [pop_wait_multi => sub { $_[0]->pop_wait_multi(1, 0) }, 0],
    [pop_back_wait => sub { $_[0]->pop_back_wait(0) }, 1],
);

for my $method (qw(push_wait push_front_wait)) {
    for my $case (@removals) {
        my ($name, $remove, $back) = @$case;
        subtest "$method after $name frees arena space" => sub {
            my $q = Data::Queue::Shared::Str->new(undef, 4, 4096);
            $q->push('K' x $_) for ($back ? (3072, 256, 256, 512) : (512, 3072, 256, 256));
            pipe(my $reader, my $writer) or die "pipe: $!";

            for my $len (1024, 256) {
                my $pid = fork // die "fork: $!";
                if (!$pid) {
                    close $reader;
                    my $ok = $q->$method('P' x $len, 3);
                    syswrite($writer, $ok ? ($len == 256 ? 'S' : 'L') : 'F');
                    _exit($ok ? 0 : 1);
                }
                push @children, $pid;
                my $deadline = time + 1;
                sleep .001 while $q->stats->{push_waiters} < @children && time < $deadline;
                is $q->stats->{push_waiters}, scalar @children, "$len-byte producer is waiting";
            }
            close $writer;
            $remove->($q);
            my @ready = IO::Select->new($reader)->can_read(1);
            my $result = '';
            sysread($reader, $result, 1) if @ready;
            is $result, 'S', 'smaller producer runs before timeout; larger value still cannot fit';

            $q->clear;
            for my $pid (@children) {
                waitpid($pid, 0);
                is $?, 0, 'producer completed successfully';
            }
            @children = ();
            close $reader;
        };
    }
}

subtest 'one removal frees bytes for multiple producers' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 8, 4096);
    $q->push('K' x 2048) for 1 .. 2;
    pipe(my $reader, my $writer) or die "pipe: $!";
    for (1 .. 2) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $reader;
            my $ok = $q->push_wait('P' x 512, 3);
            syswrite($writer, $ok ? 'S' : 'F');
            _exit($ok ? 0 : 1);
        }
        push @children, $pid;
        my $deadline = time + 1;
        sleep .001 while $q->stats->{push_waiters} < @children && time < $deadline;
    }
    close $writer;
    is $q->stats->{push_waiters}, 2, 'both producers are waiting';
    $q->pop;
    my $result = '';
    my $deadline = time + 1;
    while (length($result) < 2 && time < $deadline) {
        last unless IO::Select->new($reader)->can_read($deadline - time);
        sysread($reader, my $byte, 1) or last;
        $result .= $byte;
    }
    is $result, 'SS', 'both producers use the freed arena bytes promptly';
    $q->clear;
    for my $pid (@children) {
        waitpid($pid, 0);
        is $?, 0, 'producer completed successfully';
    }
    @children = ();
    close $reader;
};

done_testing;
