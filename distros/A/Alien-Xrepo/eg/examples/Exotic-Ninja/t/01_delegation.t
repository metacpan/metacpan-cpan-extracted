use v5.40;
use blib;
use Test2::V0;
use Path::Tiny;
use Exotic::Ninja;
#
my $ninja = Exotic::Ninja->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no
# snapshot, store empty or xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $ninja->package_info;
    skip 'package resolved (snapshot or store); delegation already serves paths' => 8 if $info;
    is $ninja->bin_dir, (),  'bin_dir is empty before resolution';
    is $ninja->version,      undef, 'version is undef before resolution';
    is $ninja->cflags,       '',    'cflags is empty before resolution';
    is $ninja->libs,         '',    'libs is empty before resolution';
    is $ninja->libpath,      undef, 'libpath is undef before resolution';
    is $ninja->kind,         undef, 'kind is undef before resolution';
    is $ninja->dist_dir,     undef, 'dist_dir is undef before resolution';
    is $ninja->package_info, undef, 'package_info is undef before resolution';
}
SKIP: {
    my @bin = $ninja->bin_dir;
    skip 'package not installed; run `perl Build.PL` first' => 4 unless @bin;
    ok $bin[0],         'bin_dir resolved';
    ok $ninja->version, 'version resolved';
    my $exe = path( $bin[0] )->child( $^O eq 'MSWin32' ? 'ninja.exe' : 'ninja' );
    ok -e $exe,       'ninja executable findable';
    ok $exe->is_file, 'ninja executable is a file';
}
#
done_testing;
