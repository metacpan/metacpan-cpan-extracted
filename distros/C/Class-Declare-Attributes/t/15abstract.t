#!/usr/bin/perl -w
# $Revision: 1515 $

# abstract.t
#
# Ensure calls to Class::Declare::abstract() die with a suitable warning.

use strict;
use lib                               qw( t          );
use Class::Declare::Attributes::Test  qw( :constants );

# define the test type
my  $type     = 'abstract';   # testing abstract attributes and methods

# abstract attributes and methods may not be directly invoked, and are merely
# present to enfore an interface
my  @tests;   undef @tests;

# all contexts and targets will result in an error
my  @contexts = ( CTX_CLASS    , CTX_DERIVED   , CTX_PARENT , CTX_UNRELATED ,
                  CTX_INSTANCE , CTX_INHERITED , CTX_SUPER  , CTX_FOREIGN   );
my  @targets  = ( TGT_CLASS    , TGT_DERIVED   ,
                  TGT_INSTANCE , TGT_INHERITED                              );

# generate all the test permutations (which will fail)
foreach my $target ( @targets ) {
  foreach my $context ( @contexts ) {
    # add the attribute and method tests
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
