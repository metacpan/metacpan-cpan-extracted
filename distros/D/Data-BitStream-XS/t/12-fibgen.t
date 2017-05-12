#!/usr/bin/perl
use strict;
use warnings;

use Test::More   tests => 2 + 15;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

# Verify fibgen(2) is interchangeable with fib
$v->erase_for_write;
$v->put_fibgen(2, 0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_fib(-1)], [0 .. 257], "fibgen(2) -> fib  0-257");

$v->erase_for_write;
$v->put_fib(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_fibgen(2, -1)], [0 .. 257], "fib -> fibgen(2)  0-257");

foreach my $m (2 .. 16) {
  $v->erase_for_write;
  $v->put_fibgen($m, 0 .. 257);
  $v->rewind_for_read;
  is_deeply( [$v->get_fibgen($m, -1)], [0 .. 257], "fib($m) 0-257");
}
