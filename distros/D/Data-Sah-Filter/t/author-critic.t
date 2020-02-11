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

my $filenames = ['lib/Data/Sah/Filter.pm','lib/Data/Sah/Filter/js/Str/downcase.pm','lib/Data/Sah/Filter/js/Str/ltrim.pm','lib/Data/Sah/Filter/js/Str/rtrim.pm','lib/Data/Sah/Filter/js/Str/trim.pm','lib/Data/Sah/Filter/js/Str/upcase.pm','lib/Data/Sah/Filter/perl/Str/check.pm','lib/Data/Sah/Filter/perl/Str/downcase.pm','lib/Data/Sah/Filter/perl/Str/ltrim.pm','lib/Data/Sah/Filter/perl/Str/replace_map.pm','lib/Data/Sah/Filter/perl/Str/rtrim.pm','lib/Data/Sah/Filter/perl/Str/trim.pm','lib/Data/Sah/Filter/perl/Str/upcase.pm','lib/Data/Sah/FilterCommon.pm','lib/Data/Sah/FilterJS.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
