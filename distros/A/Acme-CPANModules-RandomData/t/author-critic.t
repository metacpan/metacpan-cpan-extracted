#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Acme/CPANModules/FakeData.pm','lib/Acme/CPANModules/GeneratingFakeData.pm','lib/Acme/CPANModules/GeneratingMockData.pm','lib/Acme/CPANModules/GeneratingRandomData.pm','lib/Acme/CPANModules/MockData.pm','lib/Acme/CPANModules/RandomData.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
