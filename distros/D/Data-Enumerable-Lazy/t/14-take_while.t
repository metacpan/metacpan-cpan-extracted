#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my $stream = Data::Enumerable::Lazy->from_list(0..10)
    -> take_while(sub { $_[0] <= 5 });
  is_deeply $stream->to_list, [0, 1, 2, 3, 4, 5];
}

{
  my $stream = Data::Enumerable::Lazy->from_list(0..5)
    -> take_while(sub { $_[0] <= 5 });
  is_deeply $stream->to_list, [0..5];
}

{
  my $stream = Data::Enumerable::Lazy->from_list(0..5)
    -> take_while(sub { 0 });
  is_deeply $stream->to_list, [];
}

done_testing;
