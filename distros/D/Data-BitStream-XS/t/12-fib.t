#!/usr/bin/perl
use strict;
use warnings;

use Test::More   tests => 1;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->put_fib(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_fib(-1)], [0 .. 257], 'fib 0-257');
