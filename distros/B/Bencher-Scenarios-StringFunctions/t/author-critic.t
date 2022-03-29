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

my $filenames = ['lib/Bencher/Scenario/StringFunctions/CommonPrefix.pm','lib/Bencher/Scenario/StringFunctions/Indent.pm','lib/Bencher/Scenario/StringFunctions/Trim.pm','lib/Bencher/Scenario/StringModules/Startup.pm','lib/Bencher/Scenarios/StringFunctions.pm','lib/String/Indent/Join.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
