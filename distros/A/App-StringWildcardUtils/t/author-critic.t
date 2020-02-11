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

my $filenames = ['lib/App/StringWildcardUtils.pm','script/contains-bash-wildcard','script/contains-sql-wildcard','script/convert-bash-wildcard-to-re','script/convert-bash-wildcard-to-sql-wildcard','script/parse-bash-wildcard','script/parse-sql-wildcard'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
