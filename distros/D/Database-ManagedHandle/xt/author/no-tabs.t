use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Database/ManagedHandle.pm',
    't/lib/ManagedHandleTestInstance.pm',
    't/managed-singleton-tempdb-advanced.t',
    't/managed-singleton-tempdb.t',
    't/managed-singleton.t'
);

notabs_ok($_) foreach @files;
done_testing;
