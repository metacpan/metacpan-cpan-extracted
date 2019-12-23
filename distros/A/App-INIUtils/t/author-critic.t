#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/INIUtils.pm','lib/App/INIUtils/Common.pm','script/delete-ini-key','script/delete-ini-section','script/dump-ini','script/get-ini-key','script/get-ini-section','script/grep-ini','script/insert-ini-key','script/insert-ini-section','script/list-ini-sections','script/map-ini','script/parse-ini','script/sort-ini-sections'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
