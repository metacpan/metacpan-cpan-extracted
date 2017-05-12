use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
