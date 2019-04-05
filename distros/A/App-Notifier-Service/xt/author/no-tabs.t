use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/app.pl',
    'bin/app.psgi',
    'lib/App/Notifier/Service.pm',
    't/00-compile.t',
    't/001_base.t',
    't/002_index_route.t'
);

notabs_ok($_) foreach @files;
done_testing;
