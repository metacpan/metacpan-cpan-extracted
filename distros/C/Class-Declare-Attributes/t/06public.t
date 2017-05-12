#!/usr/bin/perl -w
# $Id: 06public.t 1515 2010-08-22 14:41:53Z ian $

# public.t
#
# Ensure public methods and attributes are handled correctly.
# and attributes are handled corer

use strict;
use lib                 	            qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'public';		# testing public attributes and methods

# public attributes and methods are accessible from all defining class
# instances and derived instances, regardless of the context, and they
# are both readable and writeable
my	@tests;		undef @tests;

# define the tests that will succeed first
#   - a public attribute/method is only accessible through an object
#       instance, derived or otherwise
#   - the calling context is irrelevant for public methods and
#       attributes
my	@contexts	= ( CTX_CLASS    , CTX_DERIVED   , CTX_UNRELATED ,
  	         	    CTX_INSTANCE , CTX_INHERITED , CTX_FOREIGN   );
my	@targets	= ( TGT_INSTANCE , TGT_INHERITED );

# add the attribute and method tests
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute test to the list of tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | LIVE );

		# add the method test to the list of tests
		push @tests , ( $context | $target | METHOD    | TST_ACCESS | LIVE ,
		                $context | $target | METHOD    | TST_READ   | LIVE );
	}
}

# attempts to access a public attribute/method through a class rather
# than an instance should all fail
	@targets	= ( TGT_CLASS , TGT_DERIVED );

# add the attribute and method tests
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute test to the list of tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | DIE  ,
		                $context | $target | METHOD    | TST_ALL    | DIE  );
	}
}


# create the test object
my	$test	= Class::Declare::Attributes::Test->new( type  =>  $type  ,
  	     	                                         tests => \@tests )
					or die 'could not create test object';
# run the tests
	$test->run;
