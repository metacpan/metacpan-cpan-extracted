#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Data::RingBuffer::Time;

plan tests => 5;

my $rb;
eval { Data::RingBuffer::Time->new() } or ok($@ =~ /size not defined/, "new args");
eval { Data::RingBuffer::Time->new("x") } or ok($@ =~ /numeric in numeric/, "size");
eval { Data::RingBuffer::Time->new(0) } or ok($@ =~ /must be positive/, "zero size");
eval { Data::RingBuffer::Time->new(1)->getall("x") } or ok($@ =~ /numeric in numeric/, "zero size");
eval { Data::RingBuffer::Time->new(1)->getall(-1) } or ok($@ =~ /must be positive/, "zero size");
