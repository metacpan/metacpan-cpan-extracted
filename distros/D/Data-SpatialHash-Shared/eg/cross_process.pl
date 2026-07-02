#!/usr/bin/env perl
# Cross-process: parent builds map via memfd, child opens same fd, both insert
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::SpatialHash::Shared;
$| = 1;

my $s = Data::SpatialHash::Shared->new_memfd('sphash-demo', 1000, 0, 1.0);
my $fd = $s->memfd;

# Parent inserts some points before fork
$s->insert(10, 20, 1);
$s->insert(11, 21, 2);
$s->insert(12, 22, 3);
printf "parent: inserted 3 points, count=%d fd=%d\n", $s->count, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::SpatialHash::Shared->new_from_fd($fd);
    printf "child:  sees count=%d from parent\n", $c->count;
    $c->insert(50, 50, 100);
    $c->insert(51, 51, 101);
    printf "child:  added 2 points, count now=%d\n", $c->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, count=%d\n", $s->count;

my @near = $s->query_radius(50, 50, 5);
printf "parent: found %d points near (50,50): @near\n", scalar @near;
