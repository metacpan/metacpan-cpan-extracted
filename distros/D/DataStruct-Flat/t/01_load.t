#!/usr/bin/env perl

use Test::More;

BEGIN {
  use_ok('DataStruct::Flat')
}

my $argv = DataStruct::Flat->new;
isa_ok($argv, 'DataStruct::Flat');

done_testing;
