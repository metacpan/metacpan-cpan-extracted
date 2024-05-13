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

my $filenames = ['lib/Bencher/Scenario/Accessors/ClassStartup.pm','lib/Bencher/Scenario/Accessors/Construction.pm','lib/Bencher/Scenario/Accessors/GeneratorStartup.pm','lib/Bencher/Scenario/Accessors/Get.pm','lib/Bencher/Scenario/Accessors/Set.pm','lib/Bencher/ScenarioBundle/Accessors.pm','lib/Bencher/ScenarioUtil/Accessors.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
