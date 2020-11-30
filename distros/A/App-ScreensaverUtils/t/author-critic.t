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

my $filenames = ['lib/App/ScreensaverUtils.pm','script/activate-screensaver','script/deactivate-screensaver','script/detect-screensaver','script/disable-screensaver','script/enable-screensaver','script/get-screensaver-info','script/get-screensaver-timeout','script/noss','script/pause-screensaver','script/prevent-screensaver-activated','script/prevent-screensaver-activated-until-interrupted','script/prevent-screensaver-activated-while','script/screensaver-is-active','script/screensaver-is-enabled','script/set-screensaver-timeout'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
