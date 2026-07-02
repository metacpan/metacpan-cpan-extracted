#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;
use IO::Select;

# Cross-process update notification via the eventfd: a writer inserts points and
# signals; a watcher selects on the eventfd (fileno) and reacts -- the pattern
# for integrating the shared index into a select/poll/libev event loop.

my $s   = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);  # anon, inherited across fork
my $efd = $s->eventfd;                                          # create before fork so both share it

my $pid = fork // die "fork: $!";
if (!$pid) {                          # writer
    for my $batch (1 .. 5) {
        $s->insert(rand()*100, rand()*100, $_) for 1 .. 10;
        $s->notify;
        select undef, undef, undef, 0.05;
    }
    exit 0;
}

open my $efh, '+<&=', $efd or die "fdopen eventfd: $!";          # watcher
my $sel = IO::Select->new($efh);
my $seen = 0;
while ($seen < 5 && $sel->can_read(2)) {
    my $n = $s->eventfd_consume // next;
    $seen++;
    printf "watcher: notified (%d pending), index now holds %d points\n", $n, $s->count;
}
waitpid $pid, 0;
print "done after $seen notifications\n";
