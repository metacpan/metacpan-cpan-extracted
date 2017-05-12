#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 32;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (0 .. 31) {
  my $m = 2*$k + 1;
  $v->put_golomb($m, @a);
}

$v->rewind_for_read;
foreach my $k (0 .. 31) {
  my $m = 2*$k + 1;
  is_deeply( [$v->get_golomb($m, $nitems)], \@a, "golomb($m) 0-257");
}
