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

my $filenames = ['lib/Data/ModeMerge.pm','lib/Data/ModeMerge/Config.pm','lib/Data/ModeMerge/Mode/ADD.pm','lib/Data/ModeMerge/Mode/Base.pm','lib/Data/ModeMerge/Mode/CONCAT.pm','lib/Data/ModeMerge/Mode/DELETE.pm','lib/Data/ModeMerge/Mode/KEEP.pm','lib/Data/ModeMerge/Mode/NORMAL.pm','lib/Data/ModeMerge/Mode/SUBTRACT.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
