use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Data/Chronicle.pm',
    'lib/Data/Chronicle/Mock.pm',
    'lib/Data/Chronicle/Reader.pm',
    'lib/Data/Chronicle/Subscriber.pm',
    'lib/Data/Chronicle/Writer.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/chronicle.t',
    't/publish.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
