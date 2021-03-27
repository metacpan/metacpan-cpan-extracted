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

my $filenames = ['lib/App/BencherUtils.pm','script/bencher-code','script/bencher-for','script/bencher-module-startup-overhead','script/chart-bencher-result','script/cleanup-old-bencher-results','script/format-bencher-result','script/gen-bencher-scenario-from-cpanmodules','script/list-bencher-results','script/list-bencher-scenario-modules'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
