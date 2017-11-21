#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my $i = 0;
  my $stream = Data::Enumerable::Lazy->new({
        on_has_next => sub { $i < 10 },
        on_next     => sub { $_[0]->yield($i++) },
        is_finite   => 1,
      });
  $stream->resolve;
  is($i, 10, 'Resolves the stream');
}

done_testing;
