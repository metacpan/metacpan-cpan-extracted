#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Defined );

my $checker = t::test::make_checkdata( Defined, "Value" );

# no flags
{

   my $asserter = t::test::make_asserter_sub( $checker );
   is( dies { $asserter->( "ok" ) }, undef,
      'Defined asserter OK' );
   like( dies { $asserter->( undef ) },
      qr/^Value requires a value satisfying Defined at /,
      'Defined asserter bad' );
}

# OPf_WANT_VOID clears the result
{
   my $asserter = t::test::make_asserter_sub( $checker, 'void' );
   is( [ $asserter->( "the-value" ) ], [],
      'asserter with OPf_WANT_VOID yields nothing' );
}

t::test::free_checkdata( $checker );

done_testing;
