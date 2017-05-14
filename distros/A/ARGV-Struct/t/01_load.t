#!/usr/bin/env perl

use Test::More;

BEGIN {
  use_ok('ARGV::Struct')
}

my $argv = ARGV::Struct->new;
isa_ok($argv, 'ARGV::Struct');

done_testing;
