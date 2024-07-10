#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test";

use Data::Checks qw( Defined Object Str Isa Callable Maybe );

# Some test classes
package BaseClass {
   sub new { bless [], shift }
}
package DifferentClass {
   sub new { bless [], shift }
}
package DerivedClass {
   use base qw( BaseClass );
}
package ClassWithCodeRefify {
   sub new { bless [], shift }
   use overload '&{}' => sub {};
}

# Defined
{
   my $checker = t::test::make_checkdata( Defined, "Value", "Defined" );

   ok( t::test::check_value( $checker, "ok" ), 'Defined accepts value' );
   ok( !t::test::check_value( $checker, undef ), 'Defined rejects undef' );

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

   ok( t::test::check_value( $checker, bless [], "SomeClass" ), 'Object accepts blessed object' );
   ok( !t::test::check_value( $checker, [] ), 'Object rejects unblessed ref' );
   ok( !t::test::check_value( $checker, "not-an-object" ), 'Object rejects non-ref' );
   ok( !t::test::check_value( $checker, undef ), 'Object rejects undef' );
}

# unit constraint functions don't take arguments
{
   # Perls before 5.34 did not include argument count in the message
   my $argc_re = $^V ge v5.34 ? qr/ \(got 1; expected 0\)/ : "";

   like( dies { Defined(123) },
      qr/^Too many arguments for subroutine 'Data::Checks::Defined'$argc_re at /,
      'unit constraint functions complain if given arguments' );
}

# Isa
{
   my $checker = t::test::make_checkdata( Isa("BaseClass"), "Value", "Isa" );

   ok( t::test::check_value( $checker, BaseClass->new ),    'Isa accepts class' );
   ok( t::test::check_value( $checker, DerivedClass->new ), 'Isa accepts subclass' );

   ok( !t::test::check_value( $checker, undef ),               'Isa rejects undef' );
   ok( !t::test::check_value( $checker, "BaseClass" ),         'Isa rejects string name' );
   ok( !t::test::check_value( $checker, DifferentClass->new ), 'Isa rejects other instance' );
}

# Callable
{
   my $checker = t::test::make_checkdata( Callable, "Value", "Callable" );

   ok( t::test::check_value( $checker, sub {} ),       'Callable accepts sub {}' );
   ok( t::test::check_value( $checker, \&CORE::join ), 'Callable accepts ref to CORE::join' );
   ok( t::test::check_value( $checker, ClassWithCodeRefify->new ), 'Callable accepts object with &{}' );

   ok( !t::test::check_value( $checker, undef ), 'Callable rejects undef' );
   ok( !t::test::check_value( $checker, [] ),    'Callable rejects plain arrayref' );
   ok( !t::test::check_value( $checker, BaseClass->new ), 'Callable rejects object' );
}

# Maybe
{
   my $checker = t::test::make_checkdata( Maybe(Str), "Value", "Maybe(Str)" );

   ok( t::test::check_value( $checker, undef ),      'Maybe(Str) accepts undef' );
   ok( t::test::check_value( $checker, "a string" ), 'Maybe(Str) accepts plain string' );
   ok( t::test::check_value( $checker, 1234 ),       'Maybe(Str) accepts plain number' );

   ok( !t::test::check_value( $checker, [] ), 'Maybe(Str) rejects plain ref' );
}

done_testing;
