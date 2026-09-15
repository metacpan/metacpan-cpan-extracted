use v5.40;
use blib;
use Test2::V0;
use Exotic::SQLite3;
#
my $sqlite = Exotic::SQLite3->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no snapshot, store empty or
# xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $sqlite->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $sqlite->libpath, undef, 'libpath is undef before resolution';
    is $sqlite->ffi_lib, undef, 'ffi_lib is undef before resolution';
    is $sqlite->version, undef, 'version is undef before resolution';
    is $sqlite->kind,    undef, 'kind is undef before resolution';
    is $sqlite->cflags,  '',    'cflags is empty before resolution';
    is $sqlite->libs,    '',    'libs is empty before resolution';
    my @bins = $sqlite->bin_dir;
    is [@bins],               [],    'bin_dir is empty before resolution';
    is $sqlite->package_info, undef, 'package_info is undef before resolution';
}

# sqlite3 is a static lib: post-build delegation must serve headers and a linkable lib for
# cc_lib_flags-style consumers.
SKIP: {
    my $info = $sqlite->package_info;
    skip 'package not installed; run `perl Build.PL` first' => 3 unless $info;
    ok $sqlite->libpath,                  'libpath resolved';
    ok $sqlite->version,                  'version resolved';
    ok $sqlite->find_header('sqlite3.h'), 'sqlite3.h findable';
}
#
done_testing;
