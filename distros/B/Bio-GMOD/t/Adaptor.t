# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: Adaptor.t,v 1.2 2005/03/07 20:19:47 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Adaptor';

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = 3;
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

# Begin tests

# Some of the tests of Adaptor.pm actually need to be done through
# the superclass (and with a supplied MOD)
my $result = eval { require Bio::GMOD };
my $gmod    = Bio::GMOD->new(-mod => 'WormBase',-test_param => 'test_value',-another=>'value2');
my $adaptor = $gmod->adaptor;

# Test generic loading of params via Adaptor.pm
my $test_param = $adaptor->test_param;
ok($test_param,"generic parameter loading: $test_param");

my $another = $adaptor->another;
ok($another,"generic parameter loading: $another");
