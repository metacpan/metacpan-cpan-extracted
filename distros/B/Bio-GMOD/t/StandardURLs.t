# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: StandardURLs.t,v 1.3 2005/06/01 02:19:26 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::StandardURLs';

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = 8;
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


my $index = 1;  # Force return of C_elegans for testing...

# Some of the tests of Adaptor.pm actually need to be done through
# the superclass (and with a supplied MOD)
my $mod = Bio::GMOD::StandardURLs->new(-mod => 'WormBase');
ok($mod,'new constructor via Bio::GMOD');

# Available species
my @available_species = $mod->available_species();
ok(@available_species,"fetching available species: @available_species");

# All releases
my @releases = $mod->releases(-species=> $available_species[$index]);
ok(@releases,"fetching available releases: @releases");

# Available releases
my @available_releases = $mod->releases(-species=> $available_species[$index],-status=>'available');
ok(@available_releases,"fetching available releases: @available_releases");

# Available data sets
my ($data_sets) = $mod->datasets(-species => $available_species[$index],
				 -release => $releases[$index]);
ok($data_sets,"fetching available datasets: " . join(", ",keys %{$data_sets}));;

# Current release
my $current = $mod->get_current($available_species[$index]);
ok($current,"fetching current release: $current");

# Supported datatesets
my @supported = $mod->supported_datasets();
ok(@supported,"fetching supported datasets: @supported");

# Fetching a standard url via URL
#my $content1 = $mod->fetch(-url => $data_sets->{dna});
#ok($content1,"fetching a url by specifying URL");

# Fetching a standard url via species....
#my $content2 = $mod->fetch(-species=>$available_species[$index],
#			   -release=>$releases[$index],
#			   -dataset=>'dna');
#ok($content2,"fetching a url via species and release");

