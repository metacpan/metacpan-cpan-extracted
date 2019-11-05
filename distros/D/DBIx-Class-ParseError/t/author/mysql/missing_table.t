use lib 't/lib';
use strict;
use warnings;
use Test::Roo;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'SKIP these tests are for testing by the author';
  }
}

use Test::Requires qw(DBD::mysql Test::mysqld);

with qw(Storage::MySQL MissingTable);

run_me('missing table');

done_testing;
