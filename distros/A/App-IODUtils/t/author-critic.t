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

my $filenames = ['lib/App/IODUtils.pm','script/delete-iod-key','script/delete-iod-section','script/dump-iod','script/get-iod-key','script/get-iod-section','script/grep-iod','script/insert-iod-key','script/insert-iod-section','script/list-iod-sections','script/map-iod','script/parse-iod'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
