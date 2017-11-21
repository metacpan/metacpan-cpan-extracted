#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Enumerable::Lazy;

{
  my $enum = Data::Enumerable::Lazy->empty();
  is_deeply $enum->to_list, [], 'An empty enum resolves in an empty list';
}

done_testing;
