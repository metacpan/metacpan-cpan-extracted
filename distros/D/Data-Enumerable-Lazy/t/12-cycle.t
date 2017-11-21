#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my @list = (1, 2, 3);
  my $cycle = Data::Enumerable::Lazy->cycle(@list);
  is_deeply($cycle->take(7), [1, 2, 3, 1, 2, 3, 1], 'Cycle loops the original collection');
}

done_testing;
