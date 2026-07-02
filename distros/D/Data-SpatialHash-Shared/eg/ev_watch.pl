#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# eventfd integration with a real event loop (EV / libev): a writer process
# signals via the eventfd; an EV io watcher reacts. See eg/eventfd_watch.pl for
# a dependency-free select-based version.

eval { require EV; 1 }
    or do { print "EV not installed; see eg/eventfd_watch.pl for a select-based version\n"; exit 0 };

my $s   = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
my $efd = $s->eventfd;

my $pid = fork // die "fork: $!";
if (!$pid) {
    for (1 .. 5) {
        $s->insert(rand()*100, rand()*100, $_) for 1 .. 10;
        $s->notify;
        select undef, undef, undef, 0.05;
    }
    exit 0;
}

open my $efh, '+<&=', $efd or die "fdopen: $!";
my $seen = 0;
my $io = EV::io(fileno($efh), EV::READ(), sub {       # kept in scope so it is not GC'd
    my $n = $s->eventfd_consume // return;
    printf "EV: notified (%d), index holds %d points\n", $n, $s->count;
    EV::break() if ++$seen >= 5;
});
my $safety = EV::timer(5, 0, sub { EV::break() });    # don't hang if a signal is missed
EV::run();
waitpid $pid, 0;
print "EV watcher done after $seen notifications\n";
