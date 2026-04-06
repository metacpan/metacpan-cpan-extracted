#!/usr/bin/env perl
# Multi-process producer/consumer with blocking wait
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $path = '/tmp/prodcon_q.shm';
my $q = Data::Queue::Shared::Str->new($path, 4096);
my $num_items = 100;

# Fork a producer
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $pq = Data::Queue::Shared::Str->new($path, 4096);
    for my $i (1..$num_items) {
        $pq->push_wait("job_$i");
    }
    $pq->push_wait("DONE");
    POSIX::_exit(0);
}

# Parent is the consumer
my $count = 0;
while (1) {
    my $item = $q->pop_wait(5);
    last unless defined $item;
    last if $item eq 'DONE';
    $count++;
}
waitpid($pid, 0);
print "consumed $count items\n";

$q->unlink;
