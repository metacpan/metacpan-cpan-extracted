#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Str StrEq );

# Str
test_constraint Str => Str,
   [
      'plain string'           => "a string",
      'empty string'           => "",
      'plain integer'          => 1234,
      'object with stringifty' => ClassWithStrOverload->new,
   ],
   [
      'object with numify' => ClassWithNumOverload->new,
   ];

# Str eq set
{
   my $checker = t::test::make_checkdata( StrEq(qw( A C E )), "Value", "StrEq A, C, E" );

   ok(  t::test::check_value( $checker, "A" ), 'StrEq accepts a value' );
   ok(  t::test::check_value( $checker, "E" ), 'StrEq accepts a value' );
   ok( !t::test::check_value( $checker, "B" ), 'StrEq rejects a value not in the list' );

   my $checker_Z = t::test::make_checkdata( StrEq("Z"), "Value", "StrEq Z" );

   ok(  t::test::check_value( $checker_Z, "Z" ), 'StrEq singleton accepts the value' );
   ok( !t::test::check_value( $checker_Z, "x" ), 'StrEq singleton rejects a different value' );

   my $checker_empty = t::test::make_checkdata( StrEq(""), "Value", "StrEq empty" );

   ok(  t::test::check_value( $checker_empty, ""    ), 'StrEq empty accepts empty' );
   ok( !t::test::check_value( $checker_empty, undef ), 'StrEq empty rejects undef' );
}

done_testing;
