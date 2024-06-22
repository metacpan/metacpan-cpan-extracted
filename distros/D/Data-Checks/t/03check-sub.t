#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test";

sub CheckFunction { return $_[0] eq "ok" }

# checker as code ref
{
   my $checker = t::test::make_checkdata( \&CheckFunction, "Value", "CheckFunction" );
   ok( $checker, 'checker is defined' );

   ok( t::test::check_value( $checker, "ok" ), 'check_value OK' );
   ok( !t::test::check_value( $checker, "bad" ), 'check_value bad' );

   is( dies { t::test::assert_value( $checker, "ok" ) }, undef,
      'assert_value OK' );
   like( dies { t::test::assert_value( $checker, "bad" ) },
      qr/^Value requires a value satisfying CheckFunction at /,
      'assert_value bad' );

   t::test::free_checkdata( $checker );
}

done_testing;
