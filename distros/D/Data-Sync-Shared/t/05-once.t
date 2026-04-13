use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $once = Data::Sync::Shared::Once->new($path);
ok $once, 'created once';
ok !$once->is_done, 'not done initially';

# Enter returns true for initializer
ok $once->enter, 'enter returns true for initializer';
ok !$once->is_done, 'not done until done() called';
$once->done;
ok $once->is_done, 'done after done()';

# Second enter returns false (already done)
ok !$once->enter, 'enter returns false when already done';

# enter(0) is non-blocking
{
    my $o = Data::Sync::Shared::Once->new(undef);
    # Simulate another process holding it
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $o->enter;
        select(undef, undef, undef, 0.5);
        $o->done;
        _exit(0);
    }
    select(undef, undef, undef, 0.05);
    my $t0 = time;
    my $r = $o->enter(0);
    ok time - $t0 < 0.1, 'enter(0) did not block';
    ok !$r, 'enter(0) returns false when running';
    waitpid($pid, 0);
}

# Stats
my $s = $once->stats;
is $s->{state}, 'done', 'stats state is done';
ok $s->{is_done}, 'stats is_done';

# Reset
$once->reset;
ok !$once->is_done, 'not done after reset';

$s = $once->stats;
is $s->{state}, 'init', 'stats state is init after reset';

# Multiprocess: only one initializer
{
    my $o = Data::Sync::Shared::Once->new(undef);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $got = $o->enter(5.0);
        if ($got) {
            # I'm the initializer
            select(undef, undef, undef, 0.05);
            $o->done;
            _exit(1);  # was initializer
        }
        _exit(0);  # was waiter
    }

    my $got = $o->enter(5.0);
    if ($got) {
        select(undef, undef, undef, 0.05);
        $o->done;
    }

    waitpid($pid, 0);
    my $child_was_init = $? >> 8;
    my $parent_was_init = $got ? 1 : 0;

    # Exactly one should have been initializer
    is $parent_was_init + $child_was_init, 1,
        'exactly one initializer';
    ok $o->is_done, 'once is done after both finish';
}

# Stale initializer recovery
{
    my $o = Data::Sync::Shared::Once->new(undef);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        $o->enter;
        # Die without calling done()
        _exit(0);
    }
    waitpid($pid, 0);

    # Parent should be able to recover and become initializer
    my $got = $o->enter(5.0);
    ok $got, 'recovered stale once — became new initializer';
    $o->done;
    ok $o->is_done, 'done after stale recovery';
}

# Path
is $once->path, $path, 'path correct';

# Reopen existing
$once->reset;
my $once2 = Data::Sync::Shared::Once->new($path);
ok $once2, 'reopened existing once';
ok !$once2->is_done, 'reopened sees current state';

# Anonymous
my $ao = Data::Sync::Shared::Once->new(undef);
ok $ao, 'anonymous once';
is $ao->path, undef, 'anonymous has no path';

# memfd
my $mo = Data::Sync::Shared::Once->new_memfd("test_once");
ok $mo, 'memfd once';
ok $mo->memfd >= 0, 'memfd returns valid fd';
my $mo2 = Data::Sync::Shared::Once->new_from_fd($mo->memfd);
ok $mo2, 'new_from_fd';
$mo->enter;
$mo->done;
ok $mo2->is_done, 'memfd cross-handle visibility';

# Unlink
$once->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
