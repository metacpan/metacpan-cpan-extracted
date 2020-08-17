use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/DateTime/Format/ISO8601.pm',
    'lib/DateTime/Format/ISO8601/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bad-formats.t',
    't/base-datetime.t',
    't/cut-off-year.t',
    't/date.t',
    't/datetime.t',
    't/format-datetime.t',
    't/legacy-year.t',
    't/time.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
