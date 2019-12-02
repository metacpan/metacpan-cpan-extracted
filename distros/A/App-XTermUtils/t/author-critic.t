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

my $filenames = ['lib/App/XTermUtils.pm','script/get-term-bgcolor','script/get-term-fgcolor','script/set-term-bgcolor','script/set-term-fgcolor','script/term-bgcolor-is-dark','script/term-bgcolor-is-light','script/term-fgcolor-is-dark','script/term-fgcolor-is-light'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
