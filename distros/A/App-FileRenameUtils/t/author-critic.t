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

my $filenames = ['lib/App/FileMoveUtils.pm','lib/App/FileRenameUtils.pm','script/move-files-here','script/mv-add-prefix','script/mv-add-prefix-datestamp','script/mv-add-prefix-number','script/mv-files-to-dirs','script/mv-reverse','script/mv-swap','script/mv-to-from','script/rename-add-prefix','script/rename-add-prefix-datestamp','script/rename-add-prefix-number','script/rename-swap','script/rename-to-from'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
