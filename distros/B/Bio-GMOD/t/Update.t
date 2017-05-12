# This is -*-Perl-*- code
# Bio::GMOD Test Harness Script for Modules
# $Id: Update.t,v 1.3 2005/05/31 22:31:58 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

# Indirectly, this is also a test of the superclasses Update.pm and
# Adaptor.pm

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Admin::Update';
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

  eval { use_ok($MODULE); };
  if( $@ ) {
    print STDERR "Could not use $MODULE. Skipping tests.\n";
    $error = 1;
  }
}

exit 0 if $error;

END {
  #foreach ( $Test::More::ntest..$NUMTESTS) {
  #  skip('unable to run all of the Bio::GMOD tests',1);
  #}
  system("rm -rf t/tmpdir");
}

# Begin tests

# Test new constructor (GMOD.pm and Adaptor.pm, generic parsing of
# parameters via Adaptor::parse_params)
my $gmod  = Bio::GMOD::Admin::Update->new(-mod => 'WormBase',-test_param => 'test_value') or die;
ok ($gmod,"new constructor: $gmod");

# Test data accessors
my $adaptor = $gmod->adaptor;
ok ($adaptor,"accessor, adaptor(): $adaptor");

my $mod = $gmod->mod;
ok($mod,"accessor, mod(): $mod");

# Test generic loading of params
my $test_param = $adaptor->test_param;
ok($test_param,"generic parameter loading: $test_param");

my $result = $gmod->prepare_tmp_dir(-tmp_path => 't/tmpdir',-sync_to => 'live');
ok($result,'temp dir creation');

ok($gmod->get_available_space('/'),'check of available space');

ok($gmod->check_disk_space(-path=>'/',-required=>'0.01',-component=>'test'),'fetching disk space');

