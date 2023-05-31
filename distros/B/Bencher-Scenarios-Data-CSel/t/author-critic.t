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

my $filenames = ['lib/Bencher/Scenario/Data/CSel/Parsing.pm','lib/Bencher/Scenario/Data/CSel/Selection.pm','lib/Bencher/Scenario/Data/CSel/Startup.pm','lib/Bencher/ScenarioUtil/Data/CSel.pm','lib/Bencher/Scenarios/Data/CSel.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
