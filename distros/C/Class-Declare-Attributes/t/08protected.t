#!/usr/bin/perl -w
# $Id: 08protected.t 1515 2010-08-22 14:41:53Z ian $

# protected.t
#
# Ensure protected attributes and methods behave appropriately.

use strict;
use lib                 	            qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'protected';	# testing protected attributes and methods

# protected attributes and methods should only be accessible from
# within the defining class and inherited classes, as well as instances
# of that class heirarchy
my	@tests;		undef @tests;

# NB: these are instance methods/attributes

# first, define all the tests that will succeed: called from within
# the defining class and derived classes, and their instances
my	@contexts	= ( CTX_CLASS  , CTX_INSTANCE , CTX_DERIVED , CTX_INHERITED ,
                  CTX_PARENT , CTX_SUPER                                  );
my	@targets	= (              TGT_INSTANCE ,               TGT_INHERITED );

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
#   - access is forbidden in a unrelated or foreign object/class
	@contexts	= ( CTX_UNRELATED , CTX_FOREIGN );
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute & method tests
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL    | DIE  ,
		                $context | $target | METHOD    | TST_ALL    | DIE  );
	}
}

#   - protected methods/attributes can only be accessed through class
#       instances, and not through the classes themselves
	@contexts	= ( CTX_CLASS    , CTX_DERIVED   , CTX_UNRELATED , CTX_PARENT ,
	         	    CTX_INSTANCE , CTX_INHERITED , CTX_FOREIGN   , CTX_SUPER  );
	@targets	= ( TGT_CLASS    , TGT_DERIVED                                );
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
