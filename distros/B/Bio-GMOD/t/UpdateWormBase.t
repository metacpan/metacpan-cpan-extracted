# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: UpdateWormBase.t,v 1.3 2005/05/31 22:31:58 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG @METHODS $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Admin::Update::WormBase';
  # Three tests per
  @METHODS = qw/update fetch_acedb fetch_elegans_gff fetch_briggsae_gff 
    fetch_blast_blat analyze_logs/;

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = @METHODS + 1;
  plan tests => $NUMTESTS;

  # Try to use the module
  eval { use_ok($MODULE); };
  if( $@ ) {
    print STDERR "Could not use $MODULE. Skipping tests.\n";
    $error = 1;
  }
}

exit 0 if $error;

END {
  #  foreach ( $Test::ntest..$NUMTESTS) {
  #    skip('unable to run all of the Bio::GMOD tests',1);
  # }
}

# Begin tests

# Test the new constructor (also tests subclass)
foreach (@METHODS) {
  can_ok($MODULE,$_);
}
