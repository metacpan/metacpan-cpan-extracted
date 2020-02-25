use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/gimpgitbuild',
    'lib/App/gimpgitbuild.pm',
    'lib/App/gimpgitbuild/API/GitBuild.pm',
    'lib/App/gimpgitbuild/Command/build.pm',
    'lib/App/gimpgitbuild/Command/env.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
