use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Config/MVP/Slicer.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/match_name.t',
    't/match_package.t',
    't/merge-hash.t',
    't/merge-object.t',
    't/plugin_info.t',
    't/separator_regexp.t',
    't/slice.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
