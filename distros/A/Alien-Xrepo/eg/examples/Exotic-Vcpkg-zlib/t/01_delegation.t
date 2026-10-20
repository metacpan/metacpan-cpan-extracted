use v5.40;
use blib;
use Test2::V0;
use Exotic::Vcpkg::zlib;
#
my $vcpkg = Exotic::Vcpkg::zlib->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no snapshot, store empty or
# xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $vcpkg->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $vcpkg->libpath, undef, 'libpath is undef before resolution';
    is $vcpkg->ffi_lib, undef, 'ffi_lib is undef before resolution';
    is $vcpkg->version, undef, 'version is undef before resolution';
    is $vcpkg->kind,    undef, 'kind is undef before resolution';
    is $vcpkg->cflags,  '',    'cflags is empty before resolution';
    is $vcpkg->libs,    '',    'libs is empty before resolution';
    my @bins = $vcpkg->bin_dir;
    is [@bins],              [],    'bin_dir is empty before resolution';
    is $vcpkg->package_info, undef, 'package_info is undef before resolution';
}

# zlib is a static lib: post-build delegation must serve headers and a linkable lib for
# cc_lib_flags-style consumers.
SKIP: {
    my $info = $vcpkg->package_info;
    skip 'package not installed; run `perl Build.PL` first' => 3 unless $info;
    ok $vcpkg->libpath,               'libpath resolved';
    ok $vcpkg->version,               'version resolved';
    ok $vcpkg->find_header('zlib.h'), 'zlib.h findable';
}
#
done_testing;
