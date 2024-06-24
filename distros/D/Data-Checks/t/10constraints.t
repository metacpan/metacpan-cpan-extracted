#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test";

use Data::Checks qw( Defined Object Str Num );

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

# Defined
{
   my $checker = t::test::make_checkdata( Defined, "Value", "Defined" );

   ok( t::test::check_value( $checker, "ok" ), 'Defined permits value' );
   ok( !t::test::check_value( $checker, undef ), 'Defined forbids undef' );

   is( dies { t::test::assert_value( $checker, "ok" ) }, undef,
      'Defined assert_value OK' );
   like( dies { t::test::assert_value( $checker, undef ) },
      qr/^Value requires a value satisfying Defined at /,
      'Defined assert_value bad' );

   my $asserter = t::test::make_asserter_sub( $checker );
   is( dies { $asserter->( "ok" ) }, undef,
      'Defined asserter OK' );
   like( dies { $asserter->( undef ) },
      qr/^Value requires a value satisfying Defined at /,
      'Defined asserter bad' );

   t::test::free_checkdata( $checker );
}

# Object
{
   my $checker = t::test::make_checkdata( Object, "Value", "Object" );

   ok( t::test::check_value( $checker, bless [], "SomeClass" ), 'Object permits blessed object' );
   ok( !t::test::check_value( $checker, [] ), 'Object forbids unblessed ref' );
   ok( !t::test::check_value( $checker, "not-an-object" ), 'Object forbids non-ref' );
   ok( !t::test::check_value( $checker, undef ), 'Object forbids undef' );
}

# Str
{
   my $checker = t::test::make_checkdata( Str, "Value", "Str" );

   ok( t::test::check_value( $checker, "a string" ), 'Str permits plain string' );
   ok( t::test::check_value( $checker, "" ),         'Str permits empty string' );
   ok( t::test::check_value( $checker, 1234 ),       'Str permits plain number' );
   ok( t::test::check_value( $checker, ClassWithStrOverload->new ),
      'Str permits object with str overload' );

   ok( !t::test::check_value( $checker, undef ), 'Str forbids undef' );
   ok( !t::test::check_value( $checker, [] ),    'Str forbids plain ref' );
   ok( !t::test::check_value( $checker, ClassWithoutOverload->new ),
      'Str forbids object without overload' );
   ok( !t::test::check_value( $checker, ClassWithNumOverload->new ),
      'Str forbids object with num overload' );
}

# Num
{
   my $checker = t::test::make_checkdata( Num, "Value", "Num" );

   ok( t::test::check_value( $checker, 1234 ), 'Num permits plain integer' );
   ok( t::test::check_value( $checker, 5.67 ), 'Num permits empty float' );
   ok( t::test::check_value( $checker, "89" ), 'Num permits stringified number' );
   ok( t::test::check_value( $checker, ClassWithNumOverload->new ),
      'Num permits object with num overload' );

   ok( !t::test::check_value( $checker, undef ), 'Num forbids undef' );
   ok( !t::test::check_value( $checker, [] ),    'Num forbids plain ref' );
   ok( !t::test::check_value( $checker, ClassWithoutOverload->new ),
      'Num forbids object without overload' );
   ok( !t::test::check_value( $checker, ClassWithStrOverload->new ),
      'Num forbids object with str overload' );
}

# unit constraint functions don't take arguments
{
   # Perls before 5.34 did not include argument count in the message
   my $argc_re = $^V ge v5.34 ? qr/ \(got 1; expected 0\)/ : "";

   like( dies { Defined(123) },
      qr/^Too many arguments for subroutine 'Data::Checks::Defined'$argc_re at /,
      'unit constraint functions complain if given arguments' );
}

done_testing;
