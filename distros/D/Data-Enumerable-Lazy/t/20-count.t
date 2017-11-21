#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Enumerable::Lazy;

{
  my $stream = Data::Enumerable::Lazy->empty;
  is $stream->count(), 0, '0 elements in an empty stream';
}

{
  my $stream = Data::Enumerable::Lazy->from_list(0..9);
  is $stream->count(), 10, '10 elements from range 0..9';
}

{
  my $stream = Data::Enumerable::Lazy->infinity();
  throws_ok sub { $stream->count() }, qr(Only finite enumerables might be counted), 'An infinitive stream should not be resolved';
}

done_testing();
