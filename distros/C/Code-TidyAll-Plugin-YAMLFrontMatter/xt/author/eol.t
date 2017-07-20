use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Code/TidyAll/Plugin/YAMLFrontMatter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/FrontMatter.t',
    't/lib/Test/Code/TidyAll/Plugin/YAMLFrontMatter.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
