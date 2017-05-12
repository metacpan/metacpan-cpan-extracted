use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/DBIx/Class/InflateColumn/TimeMoment.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/lib/Test/Schema.pm',
    't/lib/Test/Schema/Result/Example.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
