#!/usr/bin/perl
# $Id: 14readwrite.t 1515 2010-08-22 14:41:53Z ian $

# readwrite.t
#
# Ensure read-write attributes behave appropriately.

use strict;
use Test::More	tests => 48;
use Test::Exception;

# declare a package with read-only instance attributes
package Test::Read::Write;

use strict;
use Class::Declare::Attributes qw( :read-write );
use vars                       qw( @ISA        );
               BEGIN { @ISA	= qw( Class::Declare::Attributes ); }

# declare a random attribute value
use constant	RANDOM	=> rand;

__PACKAGE__->declare( class      => { my_class      => rw RANDOM } ,
                      static     => { my_static     => rw RANDOM } ,
                      restricted => { my_restricted => rw RANDOM } ,
                      public     => { my_public     => rw RANDOM } ,
                      private    => { my_private    => rw RANDOM } ,
                      protected  => { my_protected  => rw RANDOM } );

# create a class method so that we can access all attributes of this class
sub cmp : class
{
	my	( $self , $attribute , $value )	= @_;

	return ( $self->$attribute() == $value );
} # cmp()

# define a method for setting the attribute value by lvalue assignment
sub lvalue : class
{
	my	( $self , $attribute , $value )	= @_;

	eval "\$self->$attribute = \$value";
	die $@		if ( $@ );		# die if we have an error

	1;	# the assignment didn't die
} # lvalue()

# define a method for setting the attribute value by argument
sub argument : class
{
	my	( $self , $attribute , $value )	= @_;

	$self->$attribute( $value );
} # argument()

1;

# return to main to resume testing
package main;

# create an instance of this object
my	$class	= 'Test::Read::Write';
my	$object;
lives_ok { $object = $class->new } "new() with read-write attributes executes";

# make sure the attributes all have the correct value
foreach ( qw( class static restricted public private protected ) ) {
	my	$attr	= 'my_' . $_;

	# the attribute should have the correct value
	ok( $object->cmp( $attr => $class->RANDOM ) ,
	    "read-write $_ attribute set correctly"  );

	# lvalue assignment should succeed
	lives_ok { $object->lvalue( $attr => length $_ ) }
	         "read-write attributes may be assigned to";
	# make sure the assignment holds
	ok( $object->cmp( $attr => length $_ ) ,
	    "read-write attribute lvalue assignment succeeded" );

	# argument assignment should not die, but the value should not be
	# assigned, either
	lives_ok { $object->argument( $attr => length $_ . $_ ) }
	         "read-write attributes argument assignment lives";
	ok( $object->cmp( $attr => length $_ . $_ ) ,
	    "read-write attribute argument assignment succeeded" );
}


# make sure that read-only public attributes may be set during object
# creation (the above tests show that they cannot be modified after
# creation)
my	$random	= rand;
lives_ok { $object = $class->new( my_public => $random ) }
         "read-write public attributes may be set in call to new()";
# make sure the value from the constructor took
ok( $object->my_public == $random ,
    "read-write public attributes set correctly in call to new()" );


# make sure the class attributes may still be accessed through the class and
# that they behave as before
foreach ( qw( class static restricted ) ) {
	my	$attr	= 'my_' . $_;

	# the attribute should have the correct value
	ok( $class->cmp( $attr => length $_ . $_ ) ,
	    "read-write $_ attribute set correctly (via class)" );

	# lvalue assignment should fail
	lives_ok { $class->lvalue( $attr => length $_ ) }
	         "read-write attributes may be assigned to (via class)";
	ok( $class->cmp( $attr => length $_ ) ,
	    "read-write $_ attribute assignment holds (via class)" );

	# argument assignment should not die, but the value should not be
	# assigned, either
	lives_ok { $class->argument( $attr => length $_ . $_ ) }
	         "read-write attributes argument assignment lives (via class)";
	ok( $class->cmp( $attr => length $_ . $_ ) ,
	    "read-write attribute argument assignment succeeded (via class)" );
}
