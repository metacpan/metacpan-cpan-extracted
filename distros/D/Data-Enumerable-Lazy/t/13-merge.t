#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my ($i1, $i2) = (1, 1);
  my @streams = (
    Data::Enumerable::Lazy->new({
        on_has_next => sub { $i1 < 10 },
        on_next     => sub { shift->yield($i1 *= 2) },
        is_finite   => 1,
      }),
    Data::Enumerable::Lazy->new({
        on_has_next => sub { $i2 < 10 },
        on_next     => sub { shift->yield($i2 *= 3) },
        is_finite   => 1,
      }),
  );
  my $merged_stream = Data::Enumerable::Lazy->merge(@streams);
  is_deeply $merged_stream->to_list, [2, 3, 4, 9, 8, 27, 16];
}

{
  my $stream = Data::Enumerable::Lazy->merge(
    Data::Enumerable::Lazy->singular(0),
    Data::Enumerable::Lazy->singular(1),
    Data::Enumerable::Lazy->singular(2),
    Data::Enumerable::Lazy->singular(3),
    Data::Enumerable::Lazy->singular(4),
  );
  is_deeply $stream->to_list, [0, 1, 2, 3, 4];
}

{
  my $stream = Data::Enumerable::Lazy->merge(
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->empty(),
  );
  is_deeply $stream->to_list, [];
}

{
  my $stream = Data::Enumerable::Lazy->merge(
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->from_list(1, 2, 3),
    Data::Enumerable::Lazy->cycle(0),
    Data::Enumerable::Lazy->singular(42),
    Data::Enumerable::Lazy->empty(),
  );
  is_deeply $stream->take(8), [1, 0, 42, 2, 0, 3, 0, 0];
}

done_testing;
