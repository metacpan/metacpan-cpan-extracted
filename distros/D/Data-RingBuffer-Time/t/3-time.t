#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Data::RingBuffer::Time;

plan tests => 8;

my $rb = Data::RingBuffer::Time->new(6);

$rb->push($_) for 1..32;

# Now $rb->[1]->{buf} is: [ 27, 28, 29, 30, 31, 32 ]

# Abuse times manually as the granularity is 1 second
$rb->[0]->{buf} = [ 1, 2, 2, 3, 4, 5 ];

is_deeply([27..32], $rb->getall(), "simple getall");
is_deeply([27..32], $rb->getall(0), "time=0 getall");
is_deeply([28..32], $rb->getall(1), "time=1 getall");
is_deeply([30..32], $rb->getall(2), "time=2 getall");
is_deeply([31..32], $rb->getall(3), "time=3 getall");
is_deeply([32], $rb->getall(4), "time=4 getall");
is_deeply([], $rb->getall(5), "time=5 getall");
is_deeply([], $rb->getall(99), "time=99 getall");
