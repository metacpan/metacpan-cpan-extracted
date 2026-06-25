#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::IS;   # int key -> string value (cached result)

# Compute-once shared cache. Many workers need the same expensive results;
# get_or_set stores each key's value once and hands every caller -- even ones
# racing to compute it -- the same stored result.

my $path  = "/tmp/dhms_memoize_$$.shm";
my $cache = Data::HashMap::Shared::IS->new($path, 1000);

sub expensive {                       # pretend this is slow / costly
    my $n = shift;
    my $r = 0;
    $r += $_ for 1 .. ($n + 1) * 1000;   # busywork
    return "f($n)=$r";
}

sub memoized {
    my ($c, $n) = @_;
    my $hit = shm_is_get $c, $n;
    return $hit if defined $hit;                  # fast path: already cached
    # miss: compute, then get_or_set so the first writer wins any race and
    # every caller observes the same value
    return shm_is_get_or_set $c, $n, expensive($n);
}

my @pids;
for my $w (1 .. 4) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $c = Data::HashMap::Shared::IS->new($path, 1000);
        memoized($c, $_ % 20) for 1 .. 200;       # 4 workers contend on 20 keys
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "cached %d distinct results (each computed once, shared across workers)\n",
    $cache->size;
print "  key 7 => ", (shm_is_get $cache, 7), "\n";

$cache->unlink;
