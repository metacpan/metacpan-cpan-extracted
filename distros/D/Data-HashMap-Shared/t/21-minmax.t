use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;

sub tmp { File::Temp::tempnam(File::Spec->tmpdir, 'shm_minmax') . '.shm' }

# the shm_* keywords are list operators: wrap the call in outer parens, never
# put parens directly after the keyword name
{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000);

    is((shm_si_max $m, "k", 50), 50, 'max on absent key inserts desired and returns it');
    is((shm_si_get $m, "k"),     50, '  ...value stored');
    is((shm_si_max $m, "k", 80), 80, 'max raises below->desired, returns new value');
    is((shm_si_max $m, "k", 30), 80, 'max no-op when already >= desired');

    is((shm_si_min $m, "k", 20), 20, 'min lowers above->desired, returns new value');
    is((shm_si_min $m, "k", 99), 20, 'min no-op when already <= desired');
    is((shm_si_min $m, "z", -5), -5, 'min on absent key inserts desired (negative)');

    unlink $path;
}

my @variants = (
    { class => 'Data::HashMap::Shared::SI',   key => 'k', key2 => 'z' },
    { class => 'Data::HashMap::Shared::SI32', key => 'k', key2 => 'z' },
    { class => 'Data::HashMap::Shared::SI16', key => 'k', key2 => 'z' },
    { class => 'Data::HashMap::Shared::II',   key => 7,   key2 => 9   },
    { class => 'Data::HashMap::Shared::I32',  key => 7,   key2 => 9   },
    { class => 'Data::HashMap::Shared::I16',  key => 7,   key2 => 9   },
);
for my $v (@variants) {
    my $path = tmp();
    my $m = $v->{class}->new($path, 1000);
    my ($k, $k2) = ($v->{key}, $v->{key2});

    is($m->max($k, 5), 5, "$v->{class}: ->max insert");
    is($m->max($k, 9), 9, "$v->{class}: ->max raise");
    is($m->max($k, 1), 9, "$v->{class}: ->max no-op when >= desired");
    is($m->min($k, 3), 3, "$v->{class}: ->min lower");
    is($m->min($k, 8), 3, "$v->{class}: ->min no-op when <= desired");
    is($m->min($k2, -4), -4, "$v->{class}: ->min insert (negative)");
    is($m->get($k), 3, "$v->{class}: final value");

    unlink $path;
}

# LRU- or TTL-enabled maps force the wrlock find-or-insert path; the fast path
# needs both off
{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000, 16);
    is($m->max("k", 5), 5, 'LRU map: max insert (slow path)');
    is($m->max("k", 9), 9, 'LRU map: max raise (slow-path update + promote)');
    is($m->max("k", 1), 9, 'LRU map: max no-op when >= desired');
    is($m->min("k", 3), 3, 'LRU map: min lower (slow-path update)');
    is($m->get("k"),    3, 'LRU map: final value');
    unlink $path;
}
{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000, 3);
    $m->max("a", 1);
    $m->max("b", 2);
    $m->max("c", 3);
    is($m->size, 3, 'LRU map at capacity');
    $m->max("d", 4);
    is($m->size, 3, 'max-insert on full LRU map evicts (size stays at max_size)');
    is($m->get("d"), 4, 'newly max-inserted key present after eviction');
    unlink $path;
}
{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000, 0, 100);
    is($m->max("k", 5), 5, 'TTL map: max insert (slow path)');
    my $rem = $m->ttl_remaining("k");
    ok(defined $rem && $rem > 0 && $rem <= 100,
        'TTL map: max-insert sets per-entry TTL from default');
    is($m->min("k", 2), 2, 'TTL map: min lower (slow-path update)');
    unlink $path;
}
{
    # min with a desired greater than the stored value discriminates: a live min
    # is a no-op (5), an expired key re-inserts the desired (100)
    my $path = tmp();
    # long default TTL: only the seeded entry expires, not the re-inserted one
    my $m = Data::HashMap::Shared::SI->new($path, 1000, 0, 60);
    $m->put_ttl("k", 5, 1);
    is($m->get("k"), 5, 'TTL map: value stored before expiry');
    Time::HiRes::sleep(1.2);
    is($m->min("k", 100), 100,
        'min on expired key re-inserts desired (expired treated as absent)');
    is($m->get("k"), 100, '  ...stored value is the re-inserted desired');
    unlink $path;
}

{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000);
    $m->put("c", 0);

    my @pids;
    for my $w (1 .. 4) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            srand($w * 7919 + $$);
            my $child = Data::HashMap::Shared::SI->new($path, 1000);
            my $local = 0;
            for (1 .. 3000) {
                my $r = int(rand(1_000_000));
                $child->max("c", $r);
                $local = $r if $r > $local;
            }
            $child->put("wmax_$w", $local);
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    local $SIG{ALRM} = sub { kill 'KILL', @pids; die "pure-max concurrency timed out\n" };
    alarm 60;
    waitpid($_, 0) for @pids;
    alarm 0;

    my $expected = 0;
    for my $w (1 .. 4) {
        my $wm = $m->get("wmax_$w");
        $expected = $wm if defined $wm && $wm > $expected;
    }
    is($m->get("c"), $expected,
        'pure max across 4 procs converges to max(all desired) -- no lost update');

    unlink $path;
}

{
    my $path = tmp();
    my $m = Data::HashMap::Shared::SI->new($path, 1000);
    $m->put("c", 0);

    my $incr_per = 500;
    my $n_incr   = 3;
    my $big      = 5_000_000;
    my @pids;

    for (1 .. $n_incr) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::SI->new($path, 1000);
            $child->incr("c") for 1 .. $incr_per;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    for my $w (1 .. 3) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            srand($w * 104729 + $$);
            my $child = Data::HashMap::Shared::SI->new($path, 1000);
            my $local = 0;
            for (1 .. 2000) {
                my $r = int(rand($big));
                $child->max("c", $r);
                $local = $r if $r > $local;
            }
            $child->put("mx_$w", $local);
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    local $SIG{ALRM} = sub { kill 'KILL', @pids; die "max+incr concurrency timed out\n" };
    alarm 60;
    waitpid($_, 0) for @pids;
    alarm 0;

    my $total_incrs = $incr_per * $n_incr;
    my $maxd = 0;
    for my $w (1 .. 3) {
        my $v = $m->get("mx_$w");
        $maxd = $v if defined $v && $v > $maxd;
    }
    my $final = $m->get("c");

    cmp_ok($final, '>=', $total_incrs, 'increments never clobbered by max (>= total incrs)');
    cmp_ok($final, '>=', $maxd,        'max snaps never lost (>= max desired)');
    cmp_ok($final, '<=', $total_incrs + $maxd,
        'no spurious inflation (<= total incrs + max desired)');

    unlink $path;
}

done_testing;
