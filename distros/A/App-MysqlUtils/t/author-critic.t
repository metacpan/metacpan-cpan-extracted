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

my $filenames = ['lib/App/MysqlUtils.pm','script/mysql-copy-rows-adjust-pk','script/mysql-drop-all-tables','script/mysql-drop-dbs','script/mysql-drop-tables','script/mysql-fill-csv-columns-from-query','script/mysql-find-identical-rows','script/mysql-query','script/mysql-run-pl-files','script/mysql-run-sql-files','script/mysql-sql-dump-extract-tables'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
