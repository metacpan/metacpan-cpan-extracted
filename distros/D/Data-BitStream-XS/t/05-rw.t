#!/usr/bin/perl
use strict;
use warnings;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

use Test::More;
plan tests => ($v->maxbits - 8 + 1);

my @a = 0 .. 255;
my $nitems = scalar @a;
foreach my $k (8 .. $v->maxbits) {
  $v->put_binword($k, @a);
}

$v->rewind_for_read;
foreach my $k (8 .. $v->maxbits) {
  is_deeply( [$v->get_binword($k, $nitems)], \@a, "binword($k) 0-255");
}
