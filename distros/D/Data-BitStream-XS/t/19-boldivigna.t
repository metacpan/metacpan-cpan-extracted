#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 15;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (1 .. 15) {
  $v->put_boldivigna($k, @a);
}

$v->rewind_for_read;
foreach my $k (1 .. 15) {
  is_deeply( [$v->get_boldivigna($k, $nitems)], \@a, "bv($k) 0-257");
}
