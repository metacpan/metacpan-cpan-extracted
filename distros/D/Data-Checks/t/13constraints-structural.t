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

is( Data::Checks::Debug::inspect_constraint( Maybe(Str) ), "Maybe(Str)",
   'debug inspect Maybe(Str)' );
is( Data::Checks::Debug::inspect_constraint( Any(Str, Object) ), "Any(Str, Object)",
   'debug inspect Any(Str, Object)' );
is( Data::Checks::Debug::inspect_constraint( All(Str, Object) ), "All(Str, Object)",
   'debug inspect All(Str, Object)' );
is( Data::Checks::Debug::inspect_constraint( All() ), "All",
   'debug inspect All()' );

# Any() or All() of 1 item might as well just be the thing
is( Data::Checks::Debug::inspect_constraint( Any(Str) ), "Str",
   'debug inspect Any(Str)' );
is( Data::Checks::Debug::inspect_constraint( All(Str) ), "Str",
   'debug inspect All(Str)' );

# Flatten trees of nested Any/Any or All/All
is( Data::Checks::Debug::inspect_constraint( Any(Str, Any(Str, Str)) ), "Any(Str, Str, Str)",
   'debug inspect Any(Str, Any(Str, Str))' );
is( Data::Checks::Debug::inspect_constraint( All(Str, All(Str, Str)) ), "All(Str, Str, Str)",
   'debug inspect All(Str, All(Str, Str))' );

# Infix | operator acts like Any()
is( Data::Checks::Debug::inspect_constraint( Str|Object ), "Any(Str, Object)",
   'debug inspect Str|Object' );
is( Data::Checks::Debug::inspect_constraint( Str|Str|Str ), "Any(Str, Str, Str)",
   'debug inspect Str|Str|Str' );

done_testing;
