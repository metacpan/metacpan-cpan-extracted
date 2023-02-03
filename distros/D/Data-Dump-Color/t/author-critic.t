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

my $filenames = ['lib/ColorTheme/Data/Dump/Color/Default16.pm','lib/ColorTheme/Data/Dump/Color/Default256.pm','lib/ColorTheme/Data/Dump/Color/Light.pm','lib/Data/Dump/Color.pm','script/demo-data-dump-color'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
