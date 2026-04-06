#!/usr/bin/env perl
# Event-loop integration with EV (requires EV module)
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

eval { require EV } or die "This example requires the EV module\n";

my $q = Data::Queue::Shared::Str->new(undef, 1024);
my $fd = $q->eventfd;

# Consumer: EV watcher fires when data is available
my $count = 0;
my $w = EV::io($fd, EV::READ(), sub {
    $q->eventfd_consume;
    while (defined(my $item = $q->pop)) {
        $count++;
        print "got: $item\n" if $count <= 5;
    }
    if ($count >= 20) {
        print "...\ntotal: $count items\n";
        EV::break();
    }
});

# Producer: fork a child that pushes items
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..20) {
        $q->push("event_$i");
        $q->notify;
        select(undef, undef, undef, 0.01);  # simulate work
    }
    POSIX::_exit(0);
}

EV::run();
waitpid($pid, 0);
