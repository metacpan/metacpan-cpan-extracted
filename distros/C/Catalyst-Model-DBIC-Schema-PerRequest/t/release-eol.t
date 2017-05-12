
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Model/DBIC/Schema/PerRequest.pm',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/Model/DB.pm',
    't/lib/TestApp/Model/DBPerRequest.pm',
    't/lib/TestApp/Schema.pm',
    't/lib/TestApp/Schema/Result/Artist.pm',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/tests.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
