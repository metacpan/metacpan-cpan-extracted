
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Helper/View/TT/Alloy.pm',
    'lib/Catalyst/View/TT/Alloy.pm',
    't/00load.t',
    't/04pkgconfig.t',
    't/05appconfig.t',
    't/06includepath.t',
    't/07render.t',
    't/author-critic.t',
    't/author-eol.t',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/View/TT/Appconfig.pm',
    't/lib/TestApp/View/TT/Includepath.pm',
    't/lib/TestApp/View/TT/Includepath2.pm',
    't/lib/TestApp/View/TT/Includepath3.pm',
    't/lib/TestApp/View/TT/Pkgconfig.pm',
    't/lib/TestApp/root/specified_template.tt',
    't/lib/TestApp/root/test.tt',
    't/lib/TestApp/root/test_include_path/testpath.tt',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
