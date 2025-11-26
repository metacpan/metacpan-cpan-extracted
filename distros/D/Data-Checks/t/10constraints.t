#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Defined Object Str Isa Can ArrayRef HashRef Callable );

# Defined
{
   my $checker = t::test::make_checkdata( Defined, "Value" );

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

# Constraints have a ->check method directly
{
   ok(  Defined->check( 123 ),   'Defined->check accepts defined value' );
   ok( !Defined->check( undef ), 'Defined->check rejects undef' );
}

# Object
test_constraint Object => Object,
   [
      'object' => BaseClass->new,
   ];

# unit constraint functions don't take arguments
{
   # Perls before 5.34 did not include argument count in the message
   my $argc_re = $^V ge v5.34 ? qr/ \(got 1; expected 0\)/ : "";

   like( dies { Defined(123) },
      qr/^Too many arguments for subroutine 'Data::Checks::Defined'$argc_re at /,
      'unit constraint functions complain if given arguments' );
}

# Isa
test_constraint Isa => Isa("BaseClass"),
   [
      'object'   => BaseClass->new,
      'subclass' => DerivedClass->new,
   ],
   [
      'class name'     => "BaseClass",
      'other instance' => DifferentClass->new,
   ];

# Can
test_constraint Can => Can("basem"),
   [
      'object'       => BaseClass->new,
      'subclass'     => DerivedClass->new,
      'package name' => "BaseClass",
   ],
   [
      'other instance' => DifferentClass->new,
   ];

# Can (multi)
test_constraint Can => Can("basem", "new", "can"),
   [
      'object'       => BaseClass->new,
      'subclass'     => DerivedClass->new,
      'package name' => "BaseClass",
   ];

# ArrayRef
test_constraint ArrayRef => ArrayRef,
   [
      'plain arrayref'  => [],
      'object with @{}' => ClassWithArrayRefify->new,
   ];

# HashRef
test_constraint HashRef => HashRef,
   [
      'plain hashref'   => {},
      'object with %{}' => ClassWithHashRefify->new,
   ];

# Callable
test_constraint Callable => Callable,
   [
      'plain coderef'     => sub {},
      'ref to CORE::join' => \&CORE::join,
      'object with &{}'   => ClassWithCodeRefify->new,
   ];

# Stringification
is( Data::Checks::Debug::stringify_constraint( Defined ), "Defined",
   'debug stringify Defined' );
is( Data::Checks::Debug::stringify_constraint( Object ), "Object",
   'debug stringify Object' );
is( Data::Checks::Debug::stringify_constraint( Isa("Base::Class") ), "Isa(\"Base::Class\")",
   'debug stringify Isa("Base::Class")' );
is( Data::Checks::Debug::stringify_constraint( Can("red", "blue") ), "Can(\"red\", \"blue\")",
   'debug stringify Can("red", "blue")' );
is( Data::Checks::Debug::stringify_constraint( ArrayRef ), "ArrayRef",
   'debug stringify ArrayRef' );
is( Data::Checks::Debug::stringify_constraint( HashRef ), "HashRef",
   'debug stringify HashRef' );
is( Data::Checks::Debug::stringify_constraint( Callable ), "Callable",
   'debug stringify Callable' );

done_testing;
