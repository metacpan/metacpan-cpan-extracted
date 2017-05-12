#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 65;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (-32 .. 32) {
  $v->put_baer($k, @a);
}

$v->rewind_for_read;
foreach my $k (-32 .. 32) {
  is_deeply( [$v->get_baer($k, $nitems)], \@a, "baer($k) 0-257");
}
