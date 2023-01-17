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

my $filenames = ['lib/App/MetaCPANUtils.pm','script/diff-metacpan-releases','script/download-metacpan-release','script/list-metacpan-distribution-versions','script/list-metacpan-distributions','script/list-metacpan-releases','script/list-recent-metacpan-releases','script/open-metacpan-dist-page','script/open-metacpan-module-page'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
