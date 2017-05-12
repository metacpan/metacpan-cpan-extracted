# This is -*-Perl-*- code
# Bio::GMOD Test Harness Script for Modules
# $Id: Mirror.t,v 1.1 2005/03/07 20:19:47 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Util::Mirror';
  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;

  $NUMTESTS = 2;
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
  system("rm -rf t/tmp");
}

# Begin tests
mkdir("t/tmp");
my $mirror = Bio::GMOD::Util::Mirror->new(-host=> 'dev.wormbase.org',
					  -path=> '/pub/wormbase/README',
					  -localpath=> 't/tmp');

my $result = $mirror->mirror();
ok($result,'mirroring a file');
