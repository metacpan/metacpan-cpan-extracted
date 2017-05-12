use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/bfg',
    'lib/App/BoolFindGrep.pm',
    'lib/App/BoolFindGrep/Bool.pm',
    'lib/App/BoolFindGrep/CLI.pm',
    'lib/App/BoolFindGrep/Find.pm',
    'lib/App/BoolFindGrep/Grep.pm',
    't/00-compile.t',
    't/app-boolfindgrep-bool.t',
    't/app-boolfindgrep-grep.t',
    't/app-boolfindgrep.t'
);

notabs_ok($_) foreach @files;
done_testing;
