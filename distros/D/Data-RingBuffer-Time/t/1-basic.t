#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Data::RingBuffer::Time;

plan tests => 19;

my $rb = Data::RingBuffer::Time->new(16);

$rb->push($_) for 1..32;

my $start = 17; # 32 - size + 1
ok($_ == $start++, "sequential get") while defined($_ = $rb->get());

is_deeply([17..32], $rb->getall(), "getall");

$rb = Data::RingBuffer::Time->new(4);
$rb->push(1);
$rb->push(2);
$rb->get();
$rb->push(3);
ok($rb->get() == 2, "tail movement");
$rb->push(4);
$rb->push(5);
$rb->push(6);
ok($rb->get() == 3, "tail overflow movement");
