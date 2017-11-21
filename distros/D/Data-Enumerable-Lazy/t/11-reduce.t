#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my $res = Data::Enumerable::Lazy->from_list(1..10)->reduce(1, sub {
    $_[0] * $_[1]
  });
  is $res, 1 * 2 * 3 * 4 * 5 * 6 * 7 * 8 * 9 * 10, 'Computes 10!';
}

{
  my $res = Data::Enumerable::Lazy->from_list(1..10)->reduce({}, sub {
    $_[0]->{ $_[1] } = 1;
    $_[0]
  });

  is_deeply [sort {$a<=>$b} keys %$res], [1..10], 'Preserves the keys';
}

done_testing;
