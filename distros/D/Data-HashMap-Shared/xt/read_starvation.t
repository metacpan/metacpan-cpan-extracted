use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use File::Temp qw(tempdir);
use POSIX ();
use Data::HashMap::Shared::SS;

# A lock-free read retries while writers keep bumping the sequence; one that
# is slower than the gaps between a busy writer's sections has to fall back to
# the read lock, or it never finishes.  Two writers saturate the map here.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $dir = tempdir(CLEANUP => 1);

sub with_writers {
    my ($m, $keys, $code) = @_;
    my @pids;
    for (1, 2) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $i = 0;
            $m->put("w" . ($i++ % $keys), "y$i") while 1;
        }
        push @pids, $pid;
    }
    select undef, undef, undef, 0.2;
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    kill 'KILL', @pids;
    waitpid $_, 0 for @pids;
    return $ok ? '' : $err;
}

# A read lock the fallback failed to release would stop every writer, and the
# reads would only get faster.  One put must still finish; the default SIGALRM
# action ends a child stuck in C, where a Perl handler never runs.
sub writer_ok {
    my ($m, $key) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 10; $m->put($key => 1); POSIX::_exit(0) }
    waitpid $pid, 0;
    return $? == 0;
}

{
    my $m = Data::HashMap::Shared::SS->new("$dir/big.shm", 10_000, 0, 0, 0, 16 * 1024 * 1024);
    $m->put(big => 'b' x (1024 * 1024));
    $m->put("w$_", 'x') for 0 .. 999;
    my ($n, $max) = (0, 0);
    is with_writers($m, 1000, sub {
        local $SIG{ALRM} = sub { die "a get never finished\n" };
        alarm 20;
        for (1 .. 30) {
            my $t = time;
            my $v = $m->get('big');
            my $d = time - $t;
            $max = $d if $d > $max;
            $n++ if defined $v && length $v == 1024 * 1024;
        }
        alarm 0;
    }), '', 'reads of a 1 MB value finish under two busy writers';
    is $n, 30, 'every get of a 1 MB value under two busy writers returned it';
    cmp_ok $max, '<', 1, sprintf('the slowest took %.1f ms', $max * 1e3);
    ok writer_ok($m, 'big'), 'a writer still gets the lock afterwards';
}

{
    my $m = Data::HashMap::Shared::SS->new("$dir/full.shm", 12_000);
    my ($k, $slots) = (0, $m->max_entries * 4 / 3);   # max_entries is 3/4 of the slots
    $m->put("k" . $k++, 1) while $m->size < $slots - 84;
    is $m->capacity, $slots, "grown to all $slots slots";
    cmp_ok $m->size, '>', $slots - 100, sprintf('filled to %d of them', $m->size);
    my $max = 0;
    is with_writers($m, 1000, sub {
        local $SIG{ALRM} = sub { die "an exists never finished\n" };
        alarm 20;
        for (1 .. 200) {
            my $t = time;
            $m->exists("absent$_");
            my $d = time - $t;
            $max = $d if $d > $max;
        }
        alarm 0;
    }), '', 'misses on a nearly full table finish under two busy writers';
    cmp_ok $max, '<', 1, sprintf('a miss on a nearly full table: slowest %.1f ms', $max * 1e3);
    ok writer_ok($m, 'k0'), 'a writer still gets the lock afterwards';
}

done_testing;
