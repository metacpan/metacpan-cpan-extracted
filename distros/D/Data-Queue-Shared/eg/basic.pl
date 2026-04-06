#!/usr/bin/env perl
# Basic FIFO queue usage
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;
binmode STDOUT, ':utf8';

my $q = Data::Queue::Shared::Int->new('/tmp/basic_q.shm', 1024);

# Push / pop
$q->push(42);
$q->push(99);
print "pop: ", $q->pop, "\n";  # 42
print "pop: ", $q->pop, "\n";  # 99

# Batch
$q->push_multi(1, 2, 3, 4, 5);
my @vals = $q->pop_multi(3);
print "batch: @vals\n";  # 1 2 3

# Drain remaining
my @rest = $q->drain;
print "drain: @rest\n";  # 4 5

# String queue
my $sq = Data::Queue::Shared::Str->new('/tmp/basic_sq.shm', 1024);
$sq->push("hello world");
$sq->push("\x{263A}");  # UTF-8 smiley
print "str: ", $sq->pop, "\n";
my $utf = $sq->pop;
print "utf8: $utf (", utf8::is_utf8($utf) ? "flagged" : "bytes", ")\n";

# Cleanup
$q->unlink;
$sq->unlink;
