#!/usr/bin/perl -Tw
# $Id: 09multiple.t 1515 2010-08-22 14:41:53Z ian $

# multiple.t
#
# Ensure multiple inheritance works as advertised.

use strict;
use lib       	qw( t );
use Test::More	tests => 40;
use Test::Exception;

# so what are we testing in multiple inheritance?
#   a) are attributes and methods accessible when they are inherited?
#   b) can we redeclare attributes/methods in child classes?
#   c) can we alter the type of attributes/methods by redeclaring them?
# other aspects of multiple inheritance are either implemented by Perl
# itself (and therefore we can assume to work), or have been tested in other
# test scripts (such as execution of object initialisation routines)

# firstly, load three base classes to inherit from so that we can examine
# various permutations of multiple inheritance
#   - for these classes we're only interested in public attributes and
#       methods since we know that the other types of attributes and methods
#       will be handled correctly (as determined by the specific
#       attribute/method type tests)
#   - OK, this is putting a lot of faith in those tests, but that's what
#       they are there for

use Class::Declare::Attributes::Multi::One;
use Class::Declare::Attributes::Multi::Two;
use Class::Declare::Attributes::Multi::Three;

my	%__attr__	= reverse ( one => 1 , two => 2 , three => 3 );
my	%__inc__	= map { $_ => 1 }
  	        	      map { 'Class::Declare::Attributes::Multi::' . ucfirst }
  	        	          values %__attr__;

# OK, now we need to create derived classes
# There are a number of inheritance scenarios we should look at, and these
# will be represented by the @isa array below, where each number represents
# the base class to inherit from - two digit numbers indicates a base class
# that has been derived from two other base clases
my	@isa	= ( [ 1            ] , 	# single inheritance
  	    	    [ 1   ,  2     ] , 	# double inheritance of two single classes
  	    	    [ 1   ,  2 , 3 ] , 	# triple inheritance of single classes
  	    	    [ 12           ] , 	# inheritance with a derived class
  	    	    [ 3   , 12     ] , 	# inheritance with a derived class
  	    	    [ 123          ] );	# inheritance with a derived class

# need a routine for generating alternate class names from a given class
# name (see the explanation half-way down the following foreach() loop
my	$__rename__	= sub { # <class name>
			my	  $class			 = shift;
			my	( $base , $last )	 = m/(.*)::(.[^:]+)$/o;
				  $base				.= '::Derived';

			return join '::' , $base , map { m/([A-Z][a-z]+)/go } $last;
		}; # $__rename__()

# OK, time to create these derived classes
foreach my $isa ( @isa ) {
	local	$@;

	# derive the class names
	my	@classes	= map { join '' , map { ucfirst $_ }
	  	        	                        map { $__attr__{ $_ } } split //
	  	        	      } @{ $isa };

	# create the overall package name (derived from the inherited packages)
	my	$pkg		= 'Class::Declare::Attributes::Multi::Derived::'
	  	    		  . join( '::' , @classes );
		@classes	= map { 'Class::Declare::Attributes::Multi::' . $_ }
		        	      @classes;

	# the above naming convention ensures that all classes have unique
	# names. hoever, it also means that the names in @classes may not
	# correspond to derived class names
	#   e.g. if One and Two are the base classes, then the class One::Two
	#   will be generated, while @classes will refer to it as OneTwo
	# therefore we need to catch these cases and insert the correct (or
	# equivalent) class names
		@classes	= map { ( exists $__inc__{ $_ } )
		        	                 ? $_
		        	                 : $__rename__->( $_ )
		        	      } @classes;

	# create the class definition
	my	$dfn		= <<__EODfN__;
package $pkg;

use strict;
use base qw( @classes );

1;
__EODfN__

	# make sure we can compile this module
	eval $dfn;
	ok( ! $@ , "$pkg compiled successfully" );

	# if the compilation succeeds, then add it the the list of included
	# pacakges
	$__inc__{ $pkg }	= 1		unless ( $@ );
}

# OK, we have created the classes, so now we need to create instances of
# these classes and ensure that we can
#    a) access the attributes and methods
#    c) set the attributes in the constructor

# define the object test routines
my	$test	= sub {
		my	( $type , $object , $target , $value )	= @_;

		# make sure we can access the attribute
		lives_ok { $object->$target }
		         ref( $object ) . " access to $type granted";
		# make sure the attribute has the right value
		      ok ( $object->$target == $_[ 3 ] ,
			       ref( $object ) . " $type has correct value" );
	}; # $test()

# extract all the derived package names
foreach ( grep { m/Derived/o } sort keys %__inc__ ) {
	# create an instance of this object
	my	$object;
	lives_ok { $object = $_->new } "$_ object creation succeeds";

	# OK, attempt to access the attributes and methods
	#  - classes derived from Test::Multi::One
	/One/o		&& do {
		$test->( method    => $object => a     => 1 );
	};
	#  - classes derived from Test::Multi::Two
	/Two/o		&& do {
		$test->( method    => $object => b     => 2 );
	};
	#  - classes derived from Test::Multi::Three
	/Three/o	&& do {
		$test->( method    => $object => c     => 3 );
	};
}
