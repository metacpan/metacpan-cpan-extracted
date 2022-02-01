use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Archive/BagIt/Fast.pm',
    't/00-compile.t',
    't/fast.t',
    't/pod-coverage.t',
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
    't/verify_bag.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
