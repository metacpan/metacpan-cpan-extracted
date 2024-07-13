#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Maybe Any All Str Object NumGE NumLE );

# Maybe
test_constraint 'Maybe(Str)' => Maybe(Str),
   [
      'undef'         => undef,
      'plain string'  => "a string",
      'plain integer' => 1234,
   ];

# Any
test_constraint 'Any(Str, Object)' => Any(Str, Object),
   [
      'plain string'  => "a string",
      'plain integer' => 1234,
      'object'        => BaseClass->new,
   ];

# All(C...)
   # behaves a bit like NumRange()
test_constraint 'All(NumGE(0), NumLE(10))' => All(NumGE(0), NumLE(10)),
   [
      'zero' => 0,
      'ten'  => 10,
   ],
   [
      '20'    => 20,
   ];

# All() empty
test_constraint 'All' => All,
   [
      'undef'          => undef,
      'plain string'   => "a string",
      'plain integer'  => 1234,
      'plain arrayref' => [],
      'plain hashref'  => {},
      'plain coderef'  => sub {},
      'object',        => BaseClass->new,
   ];

done_testing;
