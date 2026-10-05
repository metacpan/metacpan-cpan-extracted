use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Archive/BagIt/Plugin/Algorithm/SHA256.pm',
    'lib/Archive/BagIt/Plugin/Manifest/SHA256.pm',
    'lib/Archive/BagIt/Plugin/SHA256.pm',
    't/00-compile.t',
    't/store_bag.t',
    't/verify_bag.t'
);

notabs_ok($_) foreach @files;
done_testing;
