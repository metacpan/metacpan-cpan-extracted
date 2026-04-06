#!/usr/bin/env perl
# Rolling buffer: fixed-capacity queue, pop oldest when full before pushing new
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $cap = 8;
my $q = Data::Queue::Shared::Str->new(undef, $cap);

# push_rolling: evict oldest if full, then push new
sub push_rolling {
    my ($q, $val) = @_;
    unless ($q->push($val)) {
        my $evicted = $q->pop;
        printf "  evicted: %s\n", $evicted;
        $q->push($val) or die "push after evict failed";
    }
}

# Simulate a stream of events into a fixed-size buffer
for my $i (1..15) {
    my $event = sprintf "event_%02d", $i;
    printf "push: %s (size: %d/%d)\n", $event, $q->size, $cap;
    push_rolling($q, $event);
}

# Dump buffer contents (most recent $cap events)
print "\nbuffer contents (oldest to newest):\n";
while (defined(my $e = $q->pop)) {
    print "  $e\n";
}
