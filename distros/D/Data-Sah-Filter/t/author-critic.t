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

my $filenames = ['lib/Data/Sah/Filter.pm','lib/Data/Sah/Filter/js/Str/downcase.pm','lib/Data/Sah/Filter/js/Str/lc.pm','lib/Data/Sah/Filter/js/Str/lcfirst.pm','lib/Data/Sah/Filter/js/Str/lowercase.pm','lib/Data/Sah/Filter/js/Str/ltrim.pm','lib/Data/Sah/Filter/js/Str/rtrim.pm','lib/Data/Sah/Filter/js/Str/trim.pm','lib/Data/Sah/Filter/js/Str/uc.pm','lib/Data/Sah/Filter/js/Str/ucfirst.pm','lib/Data/Sah/Filter/js/Str/upcase.pm','lib/Data/Sah/Filter/js/Str/uppercase.pm','lib/Data/Sah/Filter/perl/Array/remove_undef.pm','lib/Data/Sah/Filter/perl/Array/uniq.pm','lib/Data/Sah/Filter/perl/Array/uniqnum.pm','lib/Data/Sah/Filter/perl/Float/ceil.pm','lib/Data/Sah/Filter/perl/Float/check_has_fraction.pm','lib/Data/Sah/Filter/perl/Float/check_int.pm','lib/Data/Sah/Filter/perl/Float/floor.pm','lib/Data/Sah/Filter/perl/Float/round.pm','lib/Data/Sah/Filter/perl/Str/check.pm','lib/Data/Sah/Filter/perl/Str/downcase.pm','lib/Data/Sah/Filter/perl/Str/lc.pm','lib/Data/Sah/Filter/perl/Str/lcfirst.pm','lib/Data/Sah/Filter/perl/Str/lowercase.pm','lib/Data/Sah/Filter/perl/Str/ltrim.pm','lib/Data/Sah/Filter/perl/Str/oneline.pm','lib/Data/Sah/Filter/perl/Str/remove_comment.pm','lib/Data/Sah/Filter/perl/Str/remove_nondigit.pm','lib/Data/Sah/Filter/perl/Str/remove_whitespace.pm','lib/Data/Sah/Filter/perl/Str/replace_map.pm','lib/Data/Sah/Filter/perl/Str/rtrim.pm','lib/Data/Sah/Filter/perl/Str/trim.pm','lib/Data/Sah/Filter/perl/Str/uc.pm','lib/Data/Sah/Filter/perl/Str/ucfirst.pm','lib/Data/Sah/Filter/perl/Str/upcase.pm','lib/Data/Sah/Filter/perl/Str/uppercase.pm','lib/Data/Sah/Filter/perl/Str/wrap.pm','lib/Data/Sah/FilterCommon.pm','lib/Data/Sah/FilterJS.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
