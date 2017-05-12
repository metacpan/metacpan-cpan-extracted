#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 32;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (0 .. 31) {
  $v->put_rice($k, @a);
}

$v->rewind_for_read;
foreach my $k (0 .. 31) {
  is_deeply( [$v->get_rice($k, $nitems)], \@a, "rice($k) 0-257");
}
