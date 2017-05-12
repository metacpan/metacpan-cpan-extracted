#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 16;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (1 .. 16) {
  my $taboo = '0' x $k;
  $v->put_blocktaboo($taboo, @a);
}

$v->rewind_for_read;
foreach my $k (1 .. 16) {
  my $taboo = '0' x $k;
  is_deeply( [$v->get_blocktaboo($taboo, $nitems)], \@a, "blocktaboo($taboo) 0-257");
}
