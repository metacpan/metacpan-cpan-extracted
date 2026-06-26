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

my $filenames = ['lib/App/KBLIUtils.pm','script/compare-kbli-2020-2025-codes','script/get-kbli-2020-description','script/get-kbli-2020-title','script/get-kbli-2025-description','script/get-kbli-2025-title','script/list-kbli-2020-codes','script/list-kbli-2025-codes'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
