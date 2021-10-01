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

my $filenames = ['lib/App/FirefoxUtils.pm','script/firefox-has-processes','script/firefox-is-paused','script/firefox-is-running','script/get-firefox-profile-dir','script/kill-firefox','script/list-firefox-profiles','script/pause-and-unpause-firefox','script/pause-firefox','script/ps-firefox','script/restart-firefox','script/start-firefox','script/terminate-firefox','script/unpause-firefox'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
