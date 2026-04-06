#!/usr/bin/env perl
# memfd-backed queue shared across fork
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

# Create memfd queue — no filesystem path, shareable via fd
my $q = Data::Queue::Shared::Int->new_memfd("my_queue", 256);
my $fd = $q->memfd;
print "memfd: $fd\n";
print "path: ", $q->path // "(none)", "\n";

# Fork: child opens from inherited fd
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $cq = Data::Queue::Shared::Int->new_from_fd($fd);
    $cq->push($_) for 1..10;
    POSIX::_exit(0);
}

waitpid($pid, 0);
my @vals = $q->drain;
print "received from child: @vals\n";  # 1 2 3 4 5 6 7 8 9 10

# Stats
my $s = $q->stats;
print "push_ok: $s->{push_ok}, pop_ok: $s->{pop_ok}\n";
