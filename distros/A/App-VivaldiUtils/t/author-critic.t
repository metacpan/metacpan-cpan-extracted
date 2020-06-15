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

my $filenames = ['lib/App/VivaldiUtils.pm','script/kill-vivaldi','script/list-vivaldi-profiles','script/pause-vivaldi','script/ps-vivaldi','script/restart-vivaldi','script/start-vivaldi','script/terminate-vivaldi','script/unpause-vivaldi','script/vivaldi-has-processes','script/vivaldi-is-paused','script/vivaldi-is-running'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
