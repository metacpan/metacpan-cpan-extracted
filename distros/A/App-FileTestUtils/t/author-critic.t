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

my $filenames = ['lib/App/FileTestUtils.pm','script/dir-empty','script/dir-has-dot-files','script/dir-has-dot-subdirs','script/dir-has-files','script/dir-has-non-dot-files','script/dir-has-non-dot-subdirs','script/dir-has-subdirs','script/dir-not-empty','script/dir-only-has-dot-files','script/dir-only-has-dot-subdirs','script/dir-only-has-files','script/dir-only-has-non-dot-files','script/dir-only-has-non-dot-subdirs','script/dir-only-has-subdirs'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
