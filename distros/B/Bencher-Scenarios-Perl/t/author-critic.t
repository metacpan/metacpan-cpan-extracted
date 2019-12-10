#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.000

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Bencher/Scenario/Perl/5200Perf_return.pm','lib/Bencher/Scenario/Perl/5220Perf_length.pm','lib/Bencher/Scenario/Perl/Hash.pm','lib/Bencher/Scenario/Perl/Startup.pm','lib/Bencher/Scenario/Perl/Swap.pm','lib/Bencher/Scenarios/Perl.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
