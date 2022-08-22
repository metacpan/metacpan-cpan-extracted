use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/docmake',
    'lib/App/Docmake.pm',
    'lib/App/XML/DocBook/Builder.pm',
    'lib/App/XML/DocBook/Docmake.pm',
    'lib/App/XML/DocBook/Docmake/CmdComponent.pm',
    't/00-compile.t',
    't/01-use.t'
);

notabs_ok($_) foreach @files;
done_testing;
