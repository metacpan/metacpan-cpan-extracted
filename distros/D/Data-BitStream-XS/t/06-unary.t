#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 258;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

foreach my $n (0 .. 257) {
  $v->put_unary($n);
}

$v->rewind_for_read;
foreach my $n (0 .. 257) {
  my $value = $v->get_unary;
  is($value, $n);
}
