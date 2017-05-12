# This is -*-Perl-*- code
# Bio::GMOD Test Harness Script for Modules
# $Id: CheckVersions.t,v 1.2 2005/06/01 02:19:26 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

# These tests, by necessity, rely on the CheckVersions::WormBase subclass

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Util::CheckVersions';
  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = 4;
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
  #    foreach ( $Test::ntest..$NUMTESTS) {
  #      skip('unable to run all of the Bio::GMOD tests',1);
  #    }
}

# Begin tests
my $gmod  = Bio::GMOD::Util::CheckVersions->new(-mod => 'WormBase');
ok($gmod,'new constructor via Bio::GMOD');

my ($live_version) = $gmod->live_version;
ok($live_version,'live_version()');

my ($dev_version) = $gmod->development_version;
ok($dev_version,'dev_version()');

#my ($local_version) = $gmod->local_version;
#ok($local_version,'local_version()');
#
#my ($mirror_version) = $gmod->mirror_version(-site=>'http://caltech.wormbase.org/',
#					     -cgi => 'version');
#ok($mirror_version,'mirror_version()');

#TODO: {
#  local $TODO = 'checking of package versions not yet implemented';
#  can_ok($gmod,'package_version');
#}
