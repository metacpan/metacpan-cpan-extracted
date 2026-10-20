use v5.40;
use blib;
use Test2::V0;
use Exotic::Raylib6;
#
my $raylib = Exotic::Raylib6->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no
# snapshot, store empty or xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $raylib->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $raylib->libpath, undef, 'libpath is undef before resolution';
    is $raylib->ffi_lib, undef, 'ffi_lib is undef before resolution';
    is $raylib->version, undef, 'version is undef before resolution';
    is $raylib->kind,    undef, 'kind is undef before resolution';
    is $raylib->cflags,  '',    'cflags is empty before resolution';
    is $raylib->libs,    '',    'libs is empty before resolution';
    my @bins = $raylib->bin_dir;
    is [@bins],               [],    'bin_dir is empty before resolution';
    is $raylib->package_info, undef, 'package_info is undef before resolution';
}

# raylib is a shared lib: post-build delegation must serve headers and a
# loadable library for ffi_lib-style consumers.
SKIP: {
    my $info = $raylib->package_info;
    skip 'package not installed; run `perl Makefile.PL` first' => 4 unless $info;
    ok $raylib->libpath,                 'libpath resolved';
    ok $raylib->version,                 'version resolved';
    ok $raylib->find_header('raylib.h'), 'raylib.h findable';
    ok $raylib->ffi_lib,                 'ffi_lib resolved';
}
#
done_testing;
