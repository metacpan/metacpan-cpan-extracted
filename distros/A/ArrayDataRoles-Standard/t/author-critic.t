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

my $filenames = ['lib/ArrayData/Array.pm','lib/ArrayData/DBI.pm','lib/ArrayData/LinesInFile.pm','lib/ArrayData/Sample/DeNiro.pm','lib/ArrayData/Test/Source/Array.pm','lib/ArrayData/Test/Source/DBI.pm','lib/ArrayData/Test/Source/Iterator.pm','lib/ArrayData/Test/Source/LinesInDATA.pm','lib/ArrayData/Test/Source/LinesInFile.pm','lib/ArrayDataRole/Source/Array.pm','lib/ArrayDataRole/Source/DBI.pm','lib/ArrayDataRole/Source/Iterator.pm','lib/ArrayDataRole/Source/LinesInDATA.pm','lib/ArrayDataRole/Source/LinesInFile.pm','lib/ArrayDataRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
