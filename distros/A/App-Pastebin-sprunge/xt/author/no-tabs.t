use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/sprunge',
    'lib/App/Pastebin/sprunge.pm',
    't/00-compile.t',
    't/01-use.t',
    't/02-retrieve.t',
    't/03-create.t'
);

notabs_ok($_) foreach @files;
done_testing;
