#!/usr/bin/perl -Tw
# $Id: 04static.t 1515 2010-08-22 14:41:53Z ian $

# static.t
#
# Ensure static methods are handled correctly.

use strict;
use lib                             	qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'static';		# testing static methods

# static methods should only be accessible from within the
# defining class and instances of that class, just as with private attributes
# and methods, but not confined to class instances.
#
# therefore, static methods of derived classes and instances
# should be accessible, provided the access is from within the defining or
# base class (the class to which the methods are static)
my	@tests;		undef @tests;

# first, define all the tests that will succeed: called from within the
# defining class and it's instances.
my	@contexts	= ( CTX_CLASS  ,               CTX_INSTANCE                 ,
                  CTX_PARENT , CTX_SUPER                                  );
my	@targets	= ( TGT_CLASS  , TGT_DERIVED , TGT_INSTANCE , TGT_INHERITED );

# add the method tests
#   - methods should be accessible and readable
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ACCESS | LIVE ,
		                $context | $target | ATTRIBUTE | TST_READ   | LIVE ,
		                $context | $target | ATTRIBUTE | TST_WRITE  | DIE  );

		# add the method tests
		push @tests , ( $context | $target | METHOD    | TST_ACCESS | LIVE ,
		                $context | $target | METHOD    | TST_READ   | LIVE );
	}
}

# all other access permutations should die
	@contexts	= ( CTX_DERIVED   , CTX_UNRELATED ,
	        	    CTX_INHERITED , CTX_FOREIGN   );
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the method tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | DIE ,
		                $context | $target | METHOD    | TST_ALL    | DIE );
	}
}


# create the test object
my	$test	= Class::Declare::Attributes::Test->new( type  =>  $type  ,
  	     	                                         tests => \@tests )
					or die 'could not create test object';
# run the tests
	$test->run;
