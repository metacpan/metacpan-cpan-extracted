#!/usr/bin/perl -w
# $Id: 05restricted.t 1515 2010-08-22 14:41:53Z ian $

# restricted.t
#
# Ensure restricted methods and attributes are handled correctly.

use strict;
use lib                 	            qw( t          );
use Class::Declare::Attributes::Test	qw( :constants );

# define the test type
my	$type	= 'restricted';		# testing restricted attributes and methods

# restricted attributes and methods should only be accessible from within the
# defining class and instances of that class, as well as in derived classes
# and their instances, just as with protected attributes and methods, but not
# confined to class instances.
my	@tests;		undef @tests;

# NB: these are similar to class methods/attributes, in that they are
#     read-only

# first, define all the tests that will succeed: called from within the
# inheiritence tree of the defining class
my	@contexts	= ( CTX_CLASS  , CTX_DERIVED , CTX_INSTANCE , CTX_INHERITED ,
                  CTX_PARENT , CTX_SUPER                                  );
my	@targets	= ( TGT_CLASS  , TGT_DERIVED , TGT_INSTANCE , TGT_INHERITED );

# add the attribute and method tests
#   - attributes should be accessible, readable but not writeable
#   - methods should be accessible and readable
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute test
		push @tests , ( $context | $target | ATTRIBUTE | TST_ACCESS | LIVE ,
		                $context | $target | ATTRIBUTE | TST_READ   | LIVE ,
						        $context | $target | ATTRIBUTE | TST_WRITE  | DIE  );

		# add the method test
		push @tests , ( $context | $target | METHOD    | TST_ACCESS | LIVE ,
		                $context | $target | METHOD    | TST_READ   | LIVE );
	}
}

# all other access permutations (i.e. outside the inheritance tree of
# the defining class and their instances0 will fail
	@contexts	= ( CTX_UNRELATED , CTX_FOREIGN );
foreach my $target ( @targets ) {
	foreach my $context ( @contexts ) {
		# add the attribute test
		push @tests , ( $context | $target | ATTRIBUTE | TST_ALL | DIE ,
		                $context | $target | METHOD    | TST_ALL | DIE );
	}
}


# create the test object
my	$test	= Class::Declare::Attributes::Test->new( type  =>  $type  ,
  	     	                                         tests => \@tests )
					or die 'could not create test object';
# run the tests
	$test->run;
