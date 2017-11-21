#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;

{
  my $enum = Data::Enumerable::Lazy->chain(Data::Enumerable::Lazy->empty(),);
  is_deeply $enum->to_list, [], 'Resolves a single empty enum to an empty list';
}

{
  my $enum = Data::Enumerable::Lazy->chain(
    Data::Enumerable::Lazy->from_list(0..5),
    Data::Enumerable::Lazy->from_list(6..10),
    Data::Enumerable::Lazy->from_list(11..15),
  );
  is_deeply($enum->to_list, [0..15], 'Executes the enumerables one by one');
}

{
  my $enum = Data::Enumerable::Lazy->chain(
    Data::Enumerable::Lazy->from_list(0..5),
    Data::Enumerable::Lazy->empty(),
    Data::Enumerable::Lazy->from_list(6..10),
    Data::Enumerable::Lazy->empty(),
  );
  is_deeply($enum->to_list, [0..10], 'Executes the enumerables one by one with empties in the middle');
}


done_testing;
