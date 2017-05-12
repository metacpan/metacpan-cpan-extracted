#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 16;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (1 .. 16) {
  $v->put_comma($k, @a);
}

$v->rewind_for_read;
foreach my $k (1 .. 16) {
  is_deeply( [$v->get_comma($k, $nitems)], \@a, "comma($k) 0-257");
}
