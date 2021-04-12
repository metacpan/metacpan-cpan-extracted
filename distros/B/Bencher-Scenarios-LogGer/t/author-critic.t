#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Bencher/Scenario/LogGer/InitTarget.pm','lib/Bencher/Scenario/LogGer/LayoutStartup.pm','lib/Bencher/Scenario/LogGer/NullOutput.pm','lib/Bencher/Scenario/LogGer/NumericLevel.pm','lib/Bencher/Scenario/LogGer/OutputStartup.pm','lib/Bencher/Scenario/LogGer/Overhead.pm','lib/Bencher/Scenario/LogGer/StringLevel.pm','lib/Bencher/Scenarios/LogGer.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
