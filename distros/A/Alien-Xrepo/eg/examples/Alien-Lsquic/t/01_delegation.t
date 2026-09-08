use v5.40;
use blib;
use Test2::V0;
use Alien::lsquic;
#
my $lsquic = Alien::lsquic->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no
# snapshot, store empty or xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $lsquic->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $lsquic->libpath, undef, 'libpath is undef before resolution';
    is $lsquic->ffi_lib, undef, 'ffi_lib is undef before resolution';
    is $lsquic->version, undef, 'version is undef before resolution';
    is $lsquic->kind,    undef, 'kind is undef before resolution';
    is $lsquic->cflags,  '',    'cflags is empty before resolution';
    is $lsquic->libs,    '',    'libs is empty before resolution';
    my @bins = $lsquic->bin_dir;
    is [@bins],               [],    'bin_dir is empty before resolution';
    is $lsquic->package_info, undef, 'package_info is undef before resolution';
}

# lsquic is a heavy CMake/Meson/boringssl build; only validate post-build
# delegation when the snapshot or store actually resolved it.
SKIP: {
    my $info = $lsquic->package_info;
    skip 'package not installed; run `perl Build.PL` first' => 4 unless $info;
    ok $lsquic->libpath,                 'libpath resolved';
    ok $lsquic->version,                 'version resolved';
    ok $lsquic->cflags,                  'cflags resolved';
    ok $lsquic->find_header('lsquic.h'), 'lsquic.h findable';
}
#
done_testing;
