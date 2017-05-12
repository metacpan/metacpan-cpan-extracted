use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/App/Config/Chronicle.pm',
    'lib/App/Config/Chronicle/Attribute.pm',
    'lib/App/Config/Chronicle/Attribute/Global.pm',
    'lib/App/Config/Chronicle/Attribute/Section.pm',
    'lib/App/Config/Chronicle/Node.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02_attribute.t',
    't/03_section.t',
    't/04_attribute_global.t',
    't/07_full_build.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/test.yml'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
