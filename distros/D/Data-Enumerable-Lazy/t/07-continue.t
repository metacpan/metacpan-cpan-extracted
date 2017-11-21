#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Enumerable::Lazy;

{
  my $stream = Data::Enumerable::Lazy->from_list(0..9)
    -> continue({
        on_next => sub { $_[0]->yield($_[1]) },
      });
  is_deeply $stream->to_list, [0..9], 'Returns elements unchanged';
}

{
  my $stream = Data::Enumerable::Lazy->from_list(0..9)
    -> continue({
        on_next   => sub { $_[0]->yield($_[1] * $_[1]) },
        is_finite => 1,
      });
  is_deeply $stream->to_list, [map {$_ * $_} 0..9], 'Calculates squares';
}

{
  my $stream = Data::Enumerable::Lazy->empty
    -> continue({
      on_next  => sub { fail 'This should not be called' },
      is_finte => 1,
    });
  ok !defined($stream->next());
}

done_testing;
