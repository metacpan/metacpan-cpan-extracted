use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Archive/BagIt.pm',
    'lib/Archive/BagIt/Base.pm',
    'lib/Archive/BagIt/Plugin/Algorithm/MD5.pm',
    'lib/Archive/BagIt/Plugin/Algorithm/SHA512.pm',
    'lib/Archive/BagIt/Plugin/Manifest/MD5.pm',
    'lib/Archive/BagIt/Plugin/Manifest/SHA512.pm',
    'lib/Archive/BagIt/Role/Algorithm.pm',
    'lib/Archive/BagIt/Role/Manifest.pm',
    'lib/Archive/BagIt/Role/OpenSSL.pm',
    'lib/Archive/BagIt/Role/OpenSSL/Async.pm',
    'lib/Archive/BagIt/Role/OpenSSL/Sync.pm',
    'lib/Archive/BagIt/Role/Plugin.pm',
    'lib/Archive/BagIt/Role/Portability.pm',
    't/00-compile.t',
    't/00-load.t',
    't/access_bag.t',
    't/base.t',
    't/blns.license.txt',
    't/internal.t',
    't/manifest.t',
    't/naughty_strings.t',
    't/payload_files.t',
    't/pod-coverage.t',
    't/pod.t',
    't/src/dotbagit/src_bag/.bagit/bag-info.txt',
    't/src/dotbagit/src_bag/.bagit/bagit.txt',
    't/src/dotbagit/src_bag/.bagit/manifest-md5.txt',
    't/src/dotbagit/src_bag/.bagit/tagmanifest-md5.txt',
    't/src/dotbagit/src_bag/1',
    't/src/dotbagit/src_bag/2',
    't/src/dotbagit/src_files/1',
    't/src/dotbagit/src_files/2',
    't/src/src_bag/bag-info.txt',
    't/src/src_bag/bagit.txt',
    't/src/src_bag/data/1',
    't/src/src_bag/data/2',
    't/src/src_bag/manifest-md5.txt',
    't/src/src_bag/tagmanifest-md5.txt',
    't/src/src_bag_deep/bag-info.txt',
    't/src/src_bag_deep/bagit.txt',
    't/src/src_bag_deep/data/3',
    't/src/src_bag_deep/data/subdir1/1',
    't/src/src_bag_deep/data/subdir2/subsubdir/2',
    't/src/src_bag_deep/manifest-md5.txt',
    't/src/src_bag_deep/tagmanifest-md5.txt',
    't/src/src_files/1',
    't/src/src_files/2',
    't/store_bag.t',
    't/verify_bag.t',
    't/verify_simple.t'
);

notabs_ok($_) foreach @files;
done_testing;
