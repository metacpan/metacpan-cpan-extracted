#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Data::RingBuffer;

plan tests => 5;

my $rb;
eval { Data::RingBuffer->new() } or ok($@ =~ /size not defined/, "new args");
eval { Data::RingBuffer->new("x") } or ok($@ =~ /numeric in numeric/, "size");
eval { Data::RingBuffer->new(0) } or ok($@ =~ /must be positive/, "zero size");
eval {
    $rb = Data::RingBuffer->new(1, { die_overflow => 1 });
    $rb->push(1); $rb->push(2)
} or ok($@ =~ /overflow/, "overflow die");
eval {
    $rb = Data::RingBuffer->new(1, { die_overflow => 0 });
    $rb->push(1); $rb->push(2)
} and ok($rb->get() == 2, "overflow get");
