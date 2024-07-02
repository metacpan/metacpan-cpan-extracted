#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test";

use Data::Checks qw( Str StrEq );

# Some test classes
package ClassWithoutOverload {
   sub new { bless [], shift }
}
package ClassWithStrOverload {
   use overload '""' => sub { "boo" };
   sub new { bless [], shift }
}
package ClassWithNumOverload {
   use overload '0+' => sub { 123 };
   sub new { bless [], shift }
}

# Str
{
   my $checker = t::test::make_checkdata( Str, "Value", "Str" );

   ok( t::test::check_value( $checker, "a string" ), 'Str accepts plain string' );
   ok( t::test::check_value( $checker, "" ),         'Str accepts empty string' );
   ok( t::test::check_value( $checker, 1234 ),       'Str accepts plain number' );
   ok( t::test::check_value( $checker, ClassWithStrOverload->new ),
      'Str accepts object with str overload' );

   ok( !t::test::check_value( $checker, undef ), 'Str rejects undef' );
   ok( !t::test::check_value( $checker, [] ),    'Str rejects plain ref' );
   ok( !t::test::check_value( $checker, ClassWithoutOverload->new ),
      'Str rejects object without overload' );
   ok( !t::test::check_value( $checker, ClassWithNumOverload->new ),
      'Str rejects object with num overload' );
}

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
