#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 130;
use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

foreach my $n (0 .. 129) {
  $v->write(8, $n);
}

$v->rewind_for_read;

foreach my $n (0 .. 129) {
  my $value = $v->read(8);
  is($value, $n, "read 8 bits: $value");
}
