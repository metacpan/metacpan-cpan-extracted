#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Str StrEq StrMatch );

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
   my $checker = t::test::make_checkdata( StrEq(qw( A C E )), "Value" );

   ok(  t::test::check_value( $checker, "A" ), 'StrEq accepts a value' );
   ok(  t::test::check_value( $checker, "E" ), 'StrEq accepts a value' );
   ok( !t::test::check_value( $checker, "B" ), 'StrEq rejects a value not in the list' );

   my $checker_Z = t::test::make_checkdata( StrEq("Z"), "Value" );

   ok(  t::test::check_value( $checker_Z, "Z" ), 'StrEq singleton accepts the value' );
   ok( !t::test::check_value( $checker_Z, "x" ), 'StrEq singleton rejects a different value' );

   my $checker_empty = t::test::make_checkdata( StrEq(""), "Value" );

   ok(  t::test::check_value( $checker_empty, ""    ), 'StrEq empty accepts empty' );
   ok( !t::test::check_value( $checker_empty, undef ), 'StrEq empty rejects undef' );
}

# StrMatch
test_constraint 'StrMatch(qr/^[A-Z]/i)' => StrMatch(qr/^[A-Z]/i),
   [
      'plain string'    => "a string",
      'matching string' => "MATCH",
   ],
   [
      'non-matching string' => "123",
   ];

# Debug inspection
is( Data::Checks::Debug::inspect_constraint( Str ), "Str",
   'debug inspect Str' );
is( Data::Checks::Debug::inspect_constraint( StrEq("A") ), "StrEq(\"A\")",
   'debug inspect StrEq("A")' );
is( Data::Checks::Debug::inspect_constraint( StrEq("A", "B") ), "StrEq(\"A\", \"B\")",
   'debug inspect StrEq("A", "B")' );
is( Data::Checks::Debug::inspect_constraint( StrEq('"quoted value"') ), q(StrEq("\\"quoted value\\"")),
   'debug inspect StrEq(\'"quoted value"\')' );
is( Data::Checks::Debug::inspect_constraint( StrEq('literal $dollar') ), q(StrEq("literal \\$dollar")),
   'debug inspect StrEq(\'literal $dollar\')' );
is( Data::Checks::Debug::inspect_constraint( StrMatch(qr/ABC/) ), "StrMatch(qr/(?^u:ABC)/)",
   'debug inspect StrMatch(qr/ABC/)' );

done_testing;
