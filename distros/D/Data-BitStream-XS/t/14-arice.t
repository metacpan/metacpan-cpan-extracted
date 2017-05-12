#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 6;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my $k;

my @a = 0 .. 257;
my $nitems = scalar @a;

$k = 0;
$v->put_arice($k, @a);
my $endk = $k;
isnt($endk, 0, "endk ($endk) isn't 0");

$v->rewind_for_read;
$k = 0;
my @values = $v->get_arice($k, $nitems);
#  my @values;
#  push @values, $v->get_arice($k,2)  for (1 .. $nitems/2);
is($k, $endk, "endk ($endk) matches");
is_deeply( \@values, \@a, "arice get array 0-257");

# Now test one at a time.
{
  $v->erase_for_write;

  $k = 0;
  foreach my $n (0 .. 257) {
    $v->put_arice($k, $n);
  }
  is($k, $endk, "endk ($endk) matches");

  $v->rewind_for_read;
  $k = 0;
  my @values;
  foreach my $n (0 .. 257) {
    push @values, $v->get_arice($k);
  }
  is_deeply( \@values, \@a, "arice single get/put 0-257");
  is($k, $endk, "endk ($endk) matches");
}
