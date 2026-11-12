use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::Shared qw(shared_get shared_set shared_call);

my $dir = tempdir(CLEANUP => 1);

my $pid0 = $$;
my $root = Data::Shared->new($dir);
eval { $root->mount('cache', 'hashmap:ii', undef, 1000) };
if ($@) { plan skip_all => "backend unavailable: $@"; }
eval { $root->mount('visitors', 'hyperloglog', undef, 14) };
if ($@) { plan skip_all => "backend unavailable: $@"; }

shared_set($root, '/cache/42', 100);
ok -e "$dir/manifest.json", 'manifest written';
ok -e "$dir/cache.shm", 'backing file auto-named';

my $again = Data::Shared->open($dir);
is_deeply [$again->mounts], ['cache', 'visitors'], 'manifest replay mounts';
is shared_get($again, '/cache/42'), 100, 'reopened reads parent data';

my $pid = fork();
if (!defined $pid) { plan skip_all => 'fork not available'; }
if ($pid == 0) {
    my $child = Data::Shared->open($dir);
    my $ok = (shared_get($child, '/cache/42') == 100);
    shared_set($child, '/cache/43', 200) if $ok;
    exit($ok ? 0 : 1);
}
waitpid $pid, 0;
is $?, 0, 'child opened via manifest only and read';
is shared_get($root, '/cache/43'), 200, 'child write visible to parent';

my $dir2 = tempdir(CLEANUP => 1);
my $r2 = Data::Shared->new($dir2);
$r2->mount('cache', 'hashmap:ii', undef, 100);
my $native = Data::HashMap::Shared::II->new(undef, 100);
$r2->mount('temp', $native);
my $reopened = Data::Shared->open($dir2);
is_deeply [$reopened->mounts], ['cache'], 'transient mount excluded from manifest';
ok !exists { map { $_ => 1 } $reopened->mounts }->{temp}, 'temp not replayed';

# An anonymous root shares a composite index across a fork but has no file to
# reopen, so a child created by the other process lists but cannot be opened.
{
    my $anon = Data::Shared->new;
    my $mounted = eval { $anon->mount('users', ['hashmap:ss', undef, 100, ['hashmap:ss', undef, 100]]); 1 };
    my $why = $@;
    note 'anonymous composite unavailable, fork checks skipped: ' . $why
        if !$mounted && $why =~ /is not available; install the|Can't locate \S+\.pm/;
    fail "mounting an anonymous composite failed: $why"
        if !$mounted && $why !~ /is not available; install the|Can't locate \S+\.pm/;
    if ($mounted) {
        shared_set($anon, '/users/alice/name', 'from-parent');
        my $kid = fork();
        if (defined $kid) {
            if ($kid == 0) { shared_set($anon, '/users/bob/name', 'from-child'); exit 0 }
            waitpid $kid, 0;
            is_deeply [$anon->children('/users')], ['alice', 'bob'], 'forked child is listed';
            ok !eval { shared_get($anon, '/users/bob/name'); 1 }, 'but cannot be reopened';
            like $@, qr{child '/users/bob' exists in the shared index but belongs to another process},
                'the croak names the path, not the internal node role';
            like $@, qr/file-backed root/, 'and says what to do instead';
            is shared_get($anon, '/users/alice/name'), 'from-parent', 'own children unaffected';
            ok defined eval { $anon->sync_all }, 'sync_all still works over it';
        }
    }
}

# A holder killed inside a composite lifecycle section must not wedge the others.
# A futex wait ignores Perl signal handlers, so the waiter runs in its own process
# and is killed by PID, or a regression would hang the suite instead of failing it.
{
    my $anon = Data::Shared->new;
    my $mounted = eval { $anon->mount('u', ['hashmap:ss', undef, 100, ['hashmap:ss', undef, 8]]); 1 };
    my $why = $@;
    note 'anonymous composite unavailable, dead-holder check skipped: ' . $why
        if !$mounted && $why =~ /is not available; install the|Can't locate \S+\.pm/;
    fail "mounting an anonymous composite failed: $why"
        if !$mounted && $why !~ /is not available; install the|Can't locate \S+\.pm/;
    if ($mounted) {
        shared_set($anon, '/u/alice/k', 'a');
        my $holder = fork();
        if (defined $holder) {
            if ($holder == 0) {
                no warnings 'redefine';
                *Data::Shared::Composite::_parent_register = sub { kill 9, $$; sleep 5 };
                shared_set($anon, '/u/bob/k', 'b');
                POSIX::_exit(0);
            }
            waitpid $holder, 0;
            is $? & 127, 9, 'the lock holder died inside the section';

            my $waiter = fork();
            if (defined $waiter) {
                if ($waiter == 0) {
                    shared_set($anon, '/u/carol/k', 'c');
                    POSIX::_exit(0);
                }
                my $reaped = 0;
                for (1 .. 100) {
                    last if $reaped = (waitpid($waiter, POSIX::WNOHANG()) == $waiter);
                    select undef, undef, undef, 0.1;
                }
                if (!$reaped) { kill 9, $waiter; waitpid $waiter, 0 }
                ok $reaped, 'a process waiting on a dead holder\'s lock proceeds';
                is_deeply [sort $anon->children('/u')], ['alice', 'carol'],
                    'and the half-made child was not registered';
            }
        }
    }
}

done_testing;
