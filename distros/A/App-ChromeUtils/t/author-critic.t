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

my $filenames = ['lib/App/ChromeUtils.pm','script/chrome-has-processes','script/chrome-is-paused','script/chrome-is-running','script/kill-chrome','script/list-chrome-profiles','script/pause-and-unpause-chrome','script/pause-chrome','script/ps-chrome','script/restart-chrome','script/start-chrome','script/terminate-chrome','script/unpause-chrome'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
