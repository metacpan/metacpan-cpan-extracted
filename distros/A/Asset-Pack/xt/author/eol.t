use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Asset/Pack.pm',
    't/00-compile/lib_Asset_Pack_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/find_and_pack.t',
    't/internals/module_full_path.t',
    't/internals/module_rel_path.t',
    't/internals/modulify.t',
    't/internals/pack_asset_binary.t',
    't/internals/pack_asset_binary_large.t',
    't/internals/pack_metadata.t',
    't/interop/App-FatPacker.t',
    't/write_index.t',
    't/write_module.t',
    't/write_module_binary.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
