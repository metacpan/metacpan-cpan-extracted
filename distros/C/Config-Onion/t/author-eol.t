
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Config/Onion.pm',
    'lib/Config/Onion/Simple.pm',
    't/00-load.t',
    't/01-defaults.t',
    't/02-load.t',
    't/03-mixed.t',
    't/04-simple.t',
    't/05-delete.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/conf/basic.yml',
    't/conf/basic2.zzz',
    't/conf/prefix.yml',
    't/conf/withlocal.local.yml',
    't/conf/withlocal.yml'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
