use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/table2yaml',
    'lib/App/Table2YAML.pm',
    'lib/App/Table2YAML/CLI.pm',
    'lib/App/Table2YAML/Loader.pm',
    'lib/App/Table2YAML/Loader/AsciiTable.pm',
    'lib/App/Table2YAML/Loader/DSV.pm',
    'lib/App/Table2YAML/Loader/FixedWidth.pm',
    'lib/App/Table2YAML/Loader/HTML.pm',
    'lib/App/Table2YAML/Loader/LaTeX.pm',
    'lib/App/Table2YAML/Loader/Texinfo.pm',
    'lib/App/Table2YAML/Serializer.pm',
    't/00-compile.t',
    't/app-table2yaml.t'
);

notabs_ok($_) foreach @files;
done_testing;
