#!/usr/bin/perl -w
# $Id: 03class.t 1515 2010-08-22 14:41:53Z ian $

# class.t
#
# Ensure class methods and attributes are handled correctly.

use strict;
use lib                 	            qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'class';		# testing class attributes and methods

# class attributes and methods should behave the same in a class
# target, as in a class instance, an derived class and a derived
# object, so we can build our list of tests in a loop
my	@tests;		undef @tests;

# define the list of contexts
#   - class attributes/methods may be called from anywhere
my	@contexts	= ( CTX_CLASS    , CTX_DERIVED   , CTX_UNRELATED ,
  	        	    CTX_INSTANCE , CTX_INHERITED , CTX_FOREIGN   );

# define the list of targets
#   - class attributes/methods may only be called on base classes,
#     base class instances, derived classes and derived objects
my	@targets	= ( TGT_CLASS    , TGT_DERIVED   ,
  	        	    TGT_INSTANCE , TGT_INHERITED );

# add the attribute & method tests
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add this attribute test to the list of tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ACCESS | LIVE ,
		                $context | $target | ATTRIBUTE | TST_READ   | LIVE ,
		                $context | $target | ATTRIBUTE | TST_WRITE  | DIE  );

		# add this method test to the list of tests
		push @tests , ( $context | $target | METHOD    | TST_ACCESS | LIVE ,
		                $context | $target | METHOD    | TST_READ   | LIVE );
	}
}


# create the test object
my	$test	= Class::Declare::Attributes::Test->new( type  =>  $type  ,
  	     	                                         tests => \@tests )
					or die 'could not create test object';
# run the tests
	$test->run;
