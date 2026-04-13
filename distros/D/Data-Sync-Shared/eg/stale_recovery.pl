#!/usr/bin/env perl
# Stale recovery: automatic lock recovery after process death
#
# A child acquires a write lock, then dies without releasing it.
# The parent detects the stale PID and recovers automatically.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

print "=== RWLock stale recovery ===\n\n";

my $rw = Data::Sync::Shared::RWLock->new(undef);

# Child grabs wrlock and dies
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    $rw->wrlock;
    print "  child $$: acquired wrlock, dying without release...\n";
    _exit(0);
}
waitpid($pid, 0);

print "  parent: child $pid is dead, attempting wrlock...\n";
my $t0 = time;
$rw->wrlock;  # will detect stale PID and recover
my $elapsed = time - $t0;
printf "  parent: acquired wrlock in %.3fs (recovery timeout ~2s)\n", $elapsed;
$rw->wrunlock;

my $s = $rw->stats;
printf "  recoveries: %d\n\n", $s->{recoveries};

print "=== Once stale recovery ===\n\n";

my $once = Data::Sync::Shared::Once->new(undef);

# Child becomes initializer and dies
$pid = fork // die "fork: $!";
if ($pid == 0) {
    $once->enter;
    print "  child $$: became initializer, dying without done()...\n";
    _exit(0);
}
waitpid($pid, 0);

print "  parent: child $pid is dead, attempting enter...\n";
$t0 = time;
my $got = $once->enter(10);
$elapsed = time - $t0;
if ($got) {
    printf "  parent: became new initializer in %.3fs\n", $elapsed;
    $once->done;
} else {
    printf "  parent: waited for completion in %.3fs\n", $elapsed;
}

$s = $once->stats;
printf "  recoveries: %d, is_done: %d\n", $s->{recoveries}, $s->{is_done};
