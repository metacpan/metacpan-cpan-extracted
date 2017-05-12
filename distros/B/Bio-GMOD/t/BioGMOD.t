# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: BioGMOD.t,v 1.3 2005/05/16 20:10:47 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG @MODS @ORGANISMS @SPECIES $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD';
  # Three tests per
  @MODS      = qw/WormBase/;
  @ORGANISMS = qw/nematode/;
  @SPECIES   = ('briggsae','C. remanei');

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = (@MODS * 3) + (@ORGANISMS * 3) + (@SPECIES * 3);
  plan tests => $NUMTESTS + 1;

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
foreach (@MODS) {
  my $gmod  = Bio::GMOD->new(-mod => $_);
  ok ($gmod,'new constructor');

  # Test data accessors
  ok($gmod->adaptor,'accessor adaptor()');
  ok($gmod->mod,'accessor mod()');
}

# Test new via organism
foreach (@ORGANISMS) {
  my $gmod  = Bio::GMOD->new(-mod => $_);
  ok($gmod,"new constructor via organism: $_");

  # Test data accessors
  ok($gmod->adaptor,'accessor adaptor()');
  ok($gmod->mod,'accessor mod()');
}

# Test new via organism
foreach (@SPECIES) {
  my $gmod  = Bio::GMOD->new(-mod => $_);
  ok($gmod,"new constructor via species: $_");

  # Test data accessors
  ok($gmod->adaptor,'accessor adaptor()');
  ok($gmod->mod,'accessor mod()');
}
