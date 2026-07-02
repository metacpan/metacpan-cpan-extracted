#!/usr/bin/env perl
# Cross-process: parent builds the sketch via memfd, child opens the same fd,
# both count events into the one shared counter matrix.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::CountMinSketch::Shared;
$| = 1;

my $s = Data::CountMinSketch::Shared->new_memfd('cms-demo', 0.001, 0.001);
my $fd = $s->memfd;

# Parent counts a few events before fork
$s->add('login')  for 1 .. 3;
$s->add('logout') for 1 .. 2;
printf "parent: counted login x3, logout x2 (total=%d) fd=%d\n", $s->total, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec)
    my $c = Data::CountMinSketch::Shared->new_from_fd($fd);
    printf "child:  sees login=%d (total=%d) from parent\n",
        $c->estimate('login'), $c->total;
    $c->add('login')  for 1 .. 4;
    $c->add('signup') for 1 .. 5;
    printf "child:  added login x4, signup x5, total now=%d\n", $c->total;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, total=%d\n", $s->total;

# The merged stream: parent's 3 logins + child's 4, etc.
printf "parent: estimate login=%d logout=%d signup=%d\n",
    $s->estimate('login'), $s->estimate('logout'), $s->estimate('signup');
