#!/usr/bin/env perl
# Three-stage processing pipeline: parse → transform → store
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $n = 200;

# Two queues connecting three stages
my $raw_q = Data::Queue::Shared::Str->new(undef, 1024);
my $parsed_q = Data::Queue::Shared::Str->new(undef, 1024);

# Stage 1: parser (child)
my $pid1 = fork // die "fork: $!";
if ($pid1 == 0) {
    for my $i (1..$n) {
        my $raw = $raw_q->pop_wait(5);
        last unless defined $raw;
        # "parse": extract fields
        my ($name, $val) = split /=/, $raw, 2;
        $parsed_q->push_wait("$name:" . ($val // 'null'));
    }
    $parsed_q->push("__DONE__");
    POSIX::_exit(0);
}

# Stage 2: transformer (child)
my $pid2 = fork // die "fork: $!";
if ($pid2 == 0) {
    while (1) {
        my $item = $parsed_q->pop_wait(5);
        last unless defined $item;
        last if $item eq '__DONE__';
        # "transform": uppercase
        # print a few for demo

    }
    POSIX::_exit(0);
}

# Stage 0: producer (parent)
for my $i (1..$n) {
    $raw_q->push_wait("key$i=value$i");
}

waitpid($pid1, 0);
waitpid($pid2, 0);
print "pipeline processed $n items through 3 stages\n";
