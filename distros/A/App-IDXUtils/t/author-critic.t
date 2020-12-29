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

my $filenames = ['lib/App/IDXUtils.pm','script/list-idx-boards','script/list-idx-boards-static','script/list-idx-brokers','script/list-idx-brokers-static','script/list-idx-firms','script/list-idx-firms-static','script/list-idx-sectors','script/list-idx-sectors-static'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
