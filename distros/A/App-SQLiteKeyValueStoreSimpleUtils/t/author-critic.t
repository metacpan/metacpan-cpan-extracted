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

my $filenames = ['lib/App/SQLiteKeyValueStoreSimpleUtils.pm','script/check-sqlite-kvstore-key-exists','script/dump-sqlite-kvstore','script/get-sqlite-kvstore-value','script/list-sqlite-kvstore-keys','script/set-sqlite-kvstore-value'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
