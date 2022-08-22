use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/docmake',
    'lib/App/Docmake.pm',
    'lib/App/XML/DocBook/Builder.pm',
    'lib/App/XML/DocBook/Docmake.pm',
    'lib/App/XML/DocBook/Docmake/CmdComponent.pm',
    't/00-compile.t',
    't/01-use.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
