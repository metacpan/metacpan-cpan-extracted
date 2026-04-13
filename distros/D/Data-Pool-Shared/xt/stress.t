use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Pool::Shared;

my $OPS     = $ENV{STRESS_OPS}     || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 8;

diag "stress: $WORKERS workers x $OPS ops each";

# --- I64: concurrent alloc/set/get/free ---

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

my $pool = Data::Pool::Shared::I64->new($path, 64);

my $t0 = time;
my @pids;
for my $w (1..$WORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $p = Data::Pool::Shared::I64->new($path, 64);
        for (1..$OPS) {
            my $s = $p->alloc(1.0);
            next unless defined $s;
            $p->set($s, $$);
            my $v = $p->get($s);
            $p->free($s);
        }
        _exit(0);
    }
    push @pids, $pid;
}

my $fails = 0;
for (@pids) {
    waitpid($_, 0);
    $fails++ if ($? >> 8) != 0;
}
my $dt = time - $t0;

is $fails, 0, "I64 alloc/free: no worker failures";
is $pool->used, 0, "I64: all slots freed";
diag sprintf "I64: %.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

my $s = $pool->stats;
diag sprintf "I64 stats: allocs=%d frees=%d waits=%d timeouts=%d recoveries=%d",
    $s->{allocs}, $s->{frees}, $s->{waits}, $s->{timeouts}, $s->{recoveries};

# --- I64: concurrent atomic add ---

$pool->reset;
my $counter = $pool->alloc;
$pool->set($counter, 0);

@pids = ();
$t0 = time;
for my $w (1..$WORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $p = Data::Pool::Shared::I64->new($path, 64);
        for (1..$OPS) {
            $p->add($counter, 1);
        }
        _exit(0);
    }
    push @pids, $pid;
}

$fails = 0;
for (@pids) {
    waitpid($_, 0);
    $fails++ if ($? >> 8) != 0;
}
$dt = time - $t0;

is $fails, 0, "atomic add: no worker failures";
is $pool->get($counter), $WORKERS * $OPS, "atomic add: correct sum";
diag sprintf "atomic add: %.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

$pool->free($counter);

# --- Str: concurrent alloc/set/get/free ---

my $spath = tmpnam() . '.shm';
END { unlink $spath if $spath && -f $spath }

my $spool = Data::Pool::Shared::Str->new($spath, 64, 128);

@pids = ();
$t0 = time;
for my $w (1..$WORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $p = Data::Pool::Shared::Str->new($spath, 64, 128);
        for my $i (1..$OPS) {
            my $s = $p->alloc(1.0);
            next unless defined $s;
            $p->set($s, "worker=$w op=$i pid=$$");
            my $v = $p->get($s);
            $p->free($s);
        }
        _exit(0);
    }
    push @pids, $pid;
}

$fails = 0;
for (@pids) {
    waitpid($_, 0);
    $fails++ if ($? >> 8) != 0;
}
$dt = time - $t0;

is $fails, 0, "Str alloc/free: no worker failures";
is $spool->used, 0, "Str: all slots freed";
diag sprintf "Str: %.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
