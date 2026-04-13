use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $bar = Data::Sync::Shared::Barrier->new($path, 3);
ok $bar, 'created barrier';
is $bar->parties, 3, 'parties is 3';
is $bar->generation, 0, 'generation starts at 0';
is $bar->arrived, 0, 'arrived starts at 0';

# Multiprocess barrier
{
    my $b = Data::Sync::Shared::Barrier->new(undef, 3);
    my @pids;

    for my $i (1..2) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $r = $b->wait(5.0);
            _exit($r == -1 ? 99 : 0);  # 99 = timeout
        }
        push @pids, $pid;
    }

    # Parent is the 3rd party
    my $leader = $b->wait(5.0);
    ok defined $leader, 'parent passed barrier';
    ok $leader == 0 || $leader == 1, 'wait returns 0 or 1';

    for my $pid (@pids) {
        waitpid($pid, 0);
        is $? >> 8, 0, "child $pid passed barrier";
    }

    is $b->generation, 1, 'generation incremented to 1';
}

# Barrier reuse (generation increments)
{
    my $b = Data::Sync::Shared::Barrier->new(undef, 2);

    for my $round (1..3) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            $b->wait(5.0);
            _exit(0);
        }
        $b->wait(5.0);
        waitpid($pid, 0);
        is $? >> 8, 0, "round $round passed";
        is $b->generation, $round, "generation is $round";
    }
}

# Timeout
{
    my $b = Data::Sync::Shared::Barrier->new(undef, 3);
    # Only 1 party arrives, should timeout
    my $t0 = time;
    my $r = $b->wait(0.2);
    is $r, -1, 'wait timeout returns -1';
    ok time - $t0 < 2, 'did not hang';
}

# Timeout resets arrived count (barrier stays usable)
{
    my $b = Data::Sync::Shared::Barrier->new(undef, 2);
    $b->wait(0.1);  # times out, arrived should be reset
    is $b->arrived, 0, 'timeout resets arrived count';

    # Barrier should still be usable
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $b->wait(5.0);
        _exit(0);
    }
    my $r = $b->wait(5.0);
    waitpid($pid, 0);
    is $? >> 8, 0, 'barrier usable after timeout';
}

# wait(0) is non-blocking
{
    my $b = Data::Sync::Shared::Barrier->new(undef, 2);
    my $t0 = time;
    is $b->wait(0), -1, 'wait(0) returns -1 immediately';
    ok time - $t0 < 0.1, 'wait(0) did not block';
}

# Reset
$bar->reset;
is $bar->arrived, 0, 'reset clears arrived';

# Path
is $bar->path, $path, 'path correct';

# Reopen existing
my $bar2 = Data::Sync::Shared::Barrier->new($path, 3);
ok $bar2, 'reopened existing barrier';

# Stats
my $s = $bar->stats;
is $s->{parties}, 3, 'stats parties';

# Anonymous
my $ab = Data::Sync::Shared::Barrier->new(undef, 2);
ok $ab, 'anonymous barrier';
is $ab->path, undef, 'anonymous has no path';

# memfd
my $mb = Data::Sync::Shared::Barrier->new_memfd("test_bar", 2);
ok $mb, 'memfd barrier';
ok $mb->memfd >= 0, 'memfd returns valid fd';

# Unlink
$bar->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
