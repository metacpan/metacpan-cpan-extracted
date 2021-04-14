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

my $filenames = ['lib/ArrayData/Array.pm','lib/ArrayData/DBI.pm','lib/ArrayData/Test/Source/Array.pm','lib/ArrayData/Test/Source/DBI.pm','lib/ArrayData/Test/Source/Iterator.pm','lib/ArrayData/Test/Source/LinesDATA.pm','lib/ArrayDataRole/Source/Array.pm','lib/ArrayDataRole/Source/DBI.pm','lib/ArrayDataRole/Source/Iterator.pm','lib/ArrayDataRole/Source/LinesDATA.pm','lib/ArrayDataRole/Util/Random.pm','lib/ArrayDataRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
