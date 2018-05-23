use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/docmake',
    'lib/App/XML/DocBook/Builder.pm',
    'lib/App/XML/DocBook/Docmake.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-use.t',
    't/boilerplate.t'
);

notabs_ok($_) foreach @files;
done_testing;
