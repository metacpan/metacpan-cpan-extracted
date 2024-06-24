#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test";

package CheckerClass
{
   sub new { bless [], shift }
   sub check { shift; return $_[0] eq "ok" }
}

# checker as object
{
   my $checker = t::test::make_checkdata( CheckerClass->new, "Value", "CheckerClass" );
   ok( $checker, 'checker is defined' );

   ok( t::test::check_value( $checker, "ok" ), 'check_value OK' );
   ok( !t::test::check_value( $checker, "bad" ), 'check_value bad' );

   is( dies { t::test::assert_value( $checker, "ok" ) }, undef,
      'assert_value OK' );
   like( dies { t::test::assert_value( $checker, "bad" ) },
      qr/^Value requires a value satisfying CheckerClass at /,
      'assert_value bad' );

   my $asserter = t::test::make_asserter_sub( $checker );
   is( dies { $asserter->( "ok" ) }, undef,
      'asserter OK' );
   like( dies { $asserter->( "bad" ) },
      qr/^Value requires a value satisfying CheckerClass at /,
      'asserter bad' );

   t::test::free_checkdata( $checker );
}

done_testing;
