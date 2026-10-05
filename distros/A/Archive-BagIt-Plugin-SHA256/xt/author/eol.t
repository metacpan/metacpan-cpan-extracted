use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Archive/BagIt/Plugin/Algorithm/SHA256.pm',
    'lib/Archive/BagIt/Plugin/Manifest/SHA256.pm',
    'lib/Archive/BagIt/Plugin/SHA256.pm',
    't/00-compile.t',
    't/store_bag.t',
    't/verify_bag.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
