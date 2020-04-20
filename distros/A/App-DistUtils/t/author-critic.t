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

my $filenames = ['lib/App/DistUtils.pm','script/dir2dist','script/dir2mod','script/dist-dir','script/dist-has-deb','script/dist2deb','script/dist2mod','script/list-dist-contents','script/list-dist-modules','script/list-dists','script/mod2dist','script/packlist-for','script/parse-release-file-name','script/pwd2dist','script/pwd2mod','script/uninstall-dist'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
