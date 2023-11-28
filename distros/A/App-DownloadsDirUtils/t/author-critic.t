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

my $filenames = ['lib/App/DownloadsDirUtils.pm','script/foremost-download','script/hindmost-download','script/largest-download','script/list-downloads-dirs','script/mv-foremost-download-here','script/mv-hindmost-download-here','script/mv-largest-download-here','script/mv-newest-download-here','script/mv-oldest-download-here','script/mv-smallest-download-here','script/newest-download','script/oldest-download','script/smallest-download'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
