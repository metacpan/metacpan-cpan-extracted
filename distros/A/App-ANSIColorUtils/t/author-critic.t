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

my $filenames = ['lib/App/ANSIColorUtils.pm','script/ansi16-to-rgb','script/ansi256-to-rgb','script/rgb-to-ansi-bg-code','script/rgb-to-ansi-fg-code','script/rgb-to-ansi16','script/rgb-to-ansi16-bg-code','script/rgb-to-ansi16-fg-code','script/rgb-to-ansi24b-bg-code','script/rgb-to-ansi24b-fg-code','script/rgb-to-ansi256','script/rgb-to-ansi256-bg-code','script/rgb-to-ansi256-fg-code','script/show-ansi-color-table','script/show-assigned-rgb-colors','script/show-colors','script/show-colors-from-scheme','script/show-colors-from-theme','script/show-rand-rgb-colors','script/show-text-using-color-gradation'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
