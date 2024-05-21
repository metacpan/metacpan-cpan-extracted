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

my $filenames = ['lib/Bencher/Scenario/Log/ger/InitTarget.pm','lib/Bencher/Scenario/Log/ger/LayoutStartup.pm','lib/Bencher/Scenario/Log/ger/NullOutput.pm','lib/Bencher/Scenario/Log/ger/NumericLevel.pm','lib/Bencher/Scenario/Log/ger/OutputStartup.pm','lib/Bencher/Scenario/Log/ger/Overhead.pm','lib/Bencher/Scenario/Log/ger/Startup.pm','lib/Bencher/Scenario/Log/ger/StringLevel.pm','lib/Bencher/ScenarioBundle/Log/ger.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
