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

my $filenames = ['lib/ColorTheme/Test/RandomANSI16BG.pm','lib/ColorTheme/Test/RandomANSI16FG.pm','lib/ColorTheme/Test/RandomANSI16FGBG.pm','lib/ColorTheme/Test/RandomANSI256BG.pm','lib/ColorTheme/Test/RandomANSI256FG.pm','lib/ColorTheme/Test/RandomANSI256FGBG.pm','lib/ColorTheme/Test/RandomRGBBG.pm','lib/ColorTheme/Test/RandomRGBFG.pm','lib/ColorTheme/Test/RandomRGBFGBG.pm','lib/ColorThemes/Test.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
