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

my $filenames = ['lib/BorderStyle.pm','lib/BorderStyle/Test/CustomChar.pm','lib/BorderStyle/Test/Labeled.pm','lib/BorderStyleRole/Source/ASCIIArt.pm','lib/BorderStyleRole/Source/Hash.pm','lib/BorderStyleRole/Spec/Basic.pm','lib/BorderStyleRole/Transform/BoxChar.pm','lib/BorderStyleRole/Transform/InnerOnly.pm','lib/BorderStyleRole/Transform/OuterOnly.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
