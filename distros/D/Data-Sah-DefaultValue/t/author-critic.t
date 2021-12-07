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

my $filenames = ['lib/Data/Sah/DefaultValue.pm','lib/Data/Sah/DefaultValueCommon.pm','lib/Data/Sah/DefaultValueJS.pm','lib/Data/Sah/Value/js/Math/random.pm','lib/Data/Sah/Value/js/Str/repeat.pm','lib/Data/Sah/Value/perl/Math/random.pm','lib/Data/Sah/Value/perl/Str/repeat.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
