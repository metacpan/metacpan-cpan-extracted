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

my $filenames = ['lib/App/VitaminUtils.pm','script/convert-choline-unit','script/convert-cobalamin-unit','script/convert-pantothenic-acid-unit','script/convert-pyridoxine-unit','script/convert-vitamin-a-unit','script/convert-vitamin-b12-unit','script/convert-vitamin-b5-unit','script/convert-vitamin-b6-unit','script/convert-vitamin-d-unit','script/convert-vitamin-e-unit'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
