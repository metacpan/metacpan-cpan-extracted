
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dancer2/Template/Handlebars.pm',
    'lib/Dancer2/Template/Handlebars/Helpers.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-app.t',
    't/03-layout.t',
    't/layouts/layout.hbs',
    't/lib/MyHelpers.pm',
    't/views/basic.hbs',
    't/views/hello.hbs',
    't/views/helper.hbs',
    't/views/helper2.hbs',
    't/views/layouts/layout.hbs'
);

notabs_ok($_) foreach @files;
done_testing;
