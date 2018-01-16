use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/eds2xdd',
    'lib/Convert/EDS/XDD.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/does-anything.t',
    't/does-nothing.t',
    't/empty-string.t',
    't/fail.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
