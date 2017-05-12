# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: QueryWormBase.t,v 1.2 2005/06/01 02:19:26 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Query::WormBase';

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = 1;
  plan tests => $NUMTESTS;

  # Try to use the module
  eval { use_ok($MODULE); };
  if( $@ ) {
    print STDERR "Could not use $MODULE. Skipping tests.\n";
    $error = 1;
  }
}


END {
  #  foreach ( $Test::ntest..$NUMTESTS) {
  #    skip('unable to run all of the Bio::GMOD::Adaptor tests',1);
  #  }
}


