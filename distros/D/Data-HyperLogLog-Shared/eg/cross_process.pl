#!/usr/bin/env perl
# Cross-process: parent builds the HLL via memfd, child opens the same fd, both add
# into the one shared sketch -- the final estimate counts the union of both.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::HyperLogLog::Shared;
$| = 1;

my $s = Data::HyperLogLog::Shared->new_memfd('hll-demo', 14);
my $fd = $s->memfd;

# Parent adds some visitors before fork
$s->add("alice");
$s->add("bob");
$s->add("carol");
printf "parent: added 3 visitors, count=%d fd=%d\n", $s->count, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::HyperLogLog::Shared->new_from_fd($fd);
    printf "child:  sees count=%d from parent\n", $c->count;
    $c->add($_) for qw(carol dave erin);   # carol overlaps; dave and erin are new
    printf "child:  added 3 (one overlapping), count now=%d\n", $c->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, union count=%d\n", $s->count;

my $st = $s->stats;
printf "parent: %d distinct across both processes (%d registers, %d ops)\n",
    $st->{count}, $st->{registers}, $st->{ops};
