#!/usr/bin/perl -w
# $Id: 07private.t 1515 2010-08-22 14:41:53Z ian $

# private.t
#
# Ensure private methods and attributes are handled correctly.
# and attributes are handled corer

use strict;
use lib                 	            qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'private';	# testing private attributes and methods

# private attributes and methods should only be accessible from
# within the defining class and instances of that class
my	@tests;		undef @tests;

# NB: these are instance methods/attributes

# first, define all the tests that will succeed: called from within
# the defining class and it's instances, and only called on an
# instance
my	@contexts	= ( CTX_CLASS , CTX_INSTANCE , CTX_PARENT    , CTX_SUPER );
my	@targets	= (             TGT_INSTANCE , TGT_INHERITED             );

# add the attribute and method tests
#   - the attribute should be accessible, readable, and writeable
#   - methods should be accessible and readable
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute & method tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | LIVE ,
		                $context | $target | METHOD    | TST_ACCESS | LIVE ,
		                $context | $target | METHOD    | TST_READ   | LIVE );
	}
}

# all other access permutations should die
	@contexts	= ( CTX_DERIVED   , CTX_UNRELATED ,
	         	    CTX_INHERITED , CTX_FOREIGN   );
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute & method tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | DIE  ,
		                $context | $target | METHOD    | TST_ALL    | DIE  );
	}
}

	@contexts	= ( CTX_CLASS    , CTX_DERIVED   , CTX_UNRELATED , CTX_PARENT ,
	         	    CTX_INSTANCE , CTX_INHERITED , CTX_FOREIGN   , CTX_SUPER  );
	@targets	= ( TGT_CLASS    , TGT_DERIVED   );
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute & method tests
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
