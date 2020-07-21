use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/deps-app',
    'lib/App/Deps/Verify.pm',
    'lib/App/Deps/Verify/App/VerifyDeps.pm',
    'lib/App/Deps/Verify/App/VerifyDeps/Command/plinst.pm',
    'lib/App/Deps/Verify/App/VerifyDeps/Command/plupdatetask.pm',
    'lib/App/Deps/Verify/App/VerifyDeps/Command/py3list.pm',
    'lib/App/Deps/Verify/App/VerifyDeps/Command/verify.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
