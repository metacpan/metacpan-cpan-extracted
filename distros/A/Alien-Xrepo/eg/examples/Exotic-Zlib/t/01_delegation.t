use v5.40;
use blib;
use Test2::V0;
use Exotic::Zlib;
#
my $zlib = Exotic::Zlib->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no snapshot, store empty or
# xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $zlib->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $zlib->libpath, undef, 'libpath is undef before resolution';
    is $zlib->ffi_lib, undef, 'ffi_lib is undef before resolution';
    is $zlib->version, undef, 'version is undef before resolution';
    is $zlib->kind,    undef, 'kind is undef before resolution';
    is $zlib->cflags,  '',    'cflags is empty before resolution';
    is $zlib->libs,    '',    'libs is empty before resolution';
    my @bins = $zlib->bin_dir;
    is [@bins],             [],    'bin_dir is empty before resolution';
    is $zlib->package_info, undef, 'package_info is undef before resolution';
}

# zlib is a static lib: post-build delegation must serve headers and a linkable lib for
# cc_lib_flags-style consumers.
SKIP: {
    my $info = $zlib->package_info;
    skip 'package not installed; run `perl Build.PL` first' => 3 unless $info;
    ok $zlib->libpath,               'libpath resolved';
    ok $zlib->version,               'version resolved';
    ok $zlib->find_header('zlib.h'), 'zlib.h findable';
}
#
done_testing;
