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

my $filenames = ['lib/App/BraveUtils.pm','script/brave-has-processes','script/brave-is-paused','script/brave-is-running','script/kill-brave','script/pause-and-unpause-brave','script/pause-brave','script/ps-brave','script/restart-brave','script/start-brave','script/terminate-brave','script/unpause-brave'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
