#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 8;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

foreach my $n (1 .. 8) {
  $v->write(16, 0x4225 | ($n << 12));
}

$v->rewind_for_read;

foreach my $n (1 .. 8) {
  my $value = $v->read(16);
  is($value, 0x4225 | ($n << 12), "read 16 bits: $value");
}
