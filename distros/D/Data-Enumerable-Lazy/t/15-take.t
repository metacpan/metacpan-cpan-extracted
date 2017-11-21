#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my $stream = Data::Enumerable::Lazy->from_list(0..9);
  is_deeply $stream->take(10), [0..9], 'resolves the stream completely';
}

{
  my $stream = Data::Enumerable::Lazy->empty();
  is_deeply $stream->take(10), [], 'Takes no elements from an emoty enum';
}

{
  my $stream = Data::Enumerable::Lazy->singular(42);
  is_deeply $stream->take(10), [42], 'Takes the only element from a singular enum';
}

{
  my $stream = Data::Enumerable::Lazy->infinity();
  is_deeply $stream->take(10), [(undef) x 10], 'Takes 10 undefs from an infinity enum';
}

done_testing;
