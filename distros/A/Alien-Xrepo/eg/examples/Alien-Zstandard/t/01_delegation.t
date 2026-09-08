use v5.40;
use blib;
use Test2::V0;
use Alien::Zstandard;
#
my $zstd = Alien::Zstandard->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no snapshot,
# store empty or xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $zstd->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 9 if $info;
    is $zstd->libpath,               undef, 'libpath is undef before resolution';
    is $zstd->ffi_lib,               undef, 'ffi_lib is undef before resolution';
    is $zstd->version,               undef, 'version is undef before resolution';
    is $zstd->kind,                  undef, 'kind is undef before resolution';
    is $zstd->cflags,                '',    'cflags is empty before resolution';
    is $zstd->libs,                  '',    'libs is empty before resolution';
    is $zstd->find_header('zstd.h'), undef, 'find_header is undef before resolution';
    my @bins = $zstd->bin_dir;
    is [@bins],             [],    'bin_dir is empty before resolution';
    is $zstd->package_info, undef, 'package_info is undef before resolution';
}

# Resolved state (post-Build.PL snapshot, or a store that already has zstd).
SKIP: {
    my $info = $zstd->package_info;
    skip 'zstd not installed; run `perl Build.PL` first' => 7 unless $info;
    ok $zstd->libpath, 'libpath resolved';
    ok $zstd->ffi_lib, 'ffi_lib resolved';
    ok $zstd->version, 'version resolved';
    is $zstd->kind, 'library', 'kind is library';
    like $zstd->cflags, qr{-I}, 'cflags has an include flag';
    like $zstd->libs,   qr{-l}, 'libs has a link flag';
    ok $zstd->find_header('zstd.h'), 'zstd.h findable';
}
#
done_testing;
