# This is -*-Perl-*- code
## Bio::GMOD Test Harness Script for Modules
##
# $Id: Rearrange.t,v 1.1 2005/03/07 20:19:47 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  # Add the fully qualified name of the module
  $MODULE = 'Bio::GMOD::Util::Rearrange';

  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  # Change this to the appropriate number of tests
  $NUMTESTS = 4;
  plan tests => $NUMTESTS;

  # Try to use the module
  eval { use_ok($MODULE); };
  if( $@ ) {
    print STDERR "Could not use $MODULE. Skipping tests.\n";
    $error = 1;
  }
}


END {
  #foreach ( $Test::More::ntest..$NUMTESTS) {
  #  skip("unable to run all of the $MODULE tests",1);
  #}
}

# Begin tests

# Does rearrange return the values in order as expected?
my %data = ('-FIRST_SCALAR_TEST'  => 'green',
	    '-SECOND_SCALAR_TEST' => 'martians',
            '-ARRAY_TEST'  => [qw/one two three/]);
my @p = %data;
my ($first_return,$array,$second_return) = rearrange([qw/FIRST_SCALAR_TEST ARRAY_TEST SECOND_SCALAR_TEST/],@p);
is($first_return,$data{'-FIRST_SCALAR_TEST'},'rearrange(), scalar');
is($second_return,$data{'-SECOND_SCALAR_TEST'},'rearrange(), scalar');
is($array->[0],$data{'-ARRAY_TEST'}->[0],'rearrange(), array');
