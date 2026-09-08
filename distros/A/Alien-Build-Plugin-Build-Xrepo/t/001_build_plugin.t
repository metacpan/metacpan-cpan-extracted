use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test::Alien::Build qw[alienfile alienfile_ok];
use File::Temp         qw[tempdir];
use Path::Tiny;
use Alien::Xrepo;
use experimental 'class';
my $store = Path::Tiny->tempdir->stringify;

# Alien::Build ties %ENV{@PATH}/@PKG_CONFIG_PATH and unshifts bin_dir / pkg_config entries for
# every hook.  When a harness starts us without those variables defined, each unshift splits an
# undef value and Env::UNSHIFT warns ("Use of uninitialized value in split") for every hook under
# `-w`/PERL5OPT=-w.
$ENV{PATH}            = '' unless defined $ENV{PATH};
$ENV{PKG_CONFIG_PATH} = '' unless defined $ENV{PKG_CONFIG_PATH};
our $NESTED    = 0;
our @ALL_CALLS = ();

class Alien::Build::Plugin::Build::Xrepo::TestSpy {
    our %FAIL;
    field $calls : reader : param = [];

    method install ( $name, $version, %opts ) {
        push @$calls,          { action => 'install', name => $name, version => $version, opts => {%opts} };
        push @main::ALL_CALLS, { action => 'install', name => $name, version => $version, opts => {%opts} };
        die "boom on $name" if $FAIL{$name};
        return $self->_pkg( $name, $version );
    }

    method fetch ( $name, $version, %opts ) {
        push @$calls, { action => 'fetch', name => $name, version => $version, opts => {%opts} };
        return $self->_pkg( $name, $version );
    }

    method info ( $name, %opts ) {
        push @$calls, { action => 'info', name => $name, opts => {%opts} };
        return        {};
    }

    method export ( $name, $version, %opts ) {
        push @$calls, { action => 'export', name => $name, version => $version, opts => {%opts} };
        my $t = Path::Tiny->new( $opts{packagedir} // return 0 );
        $t->child('include')->mkpath;
        $t->child('lib')->mkpath;
        $t->child('bin')->mkpath;
        if ($main::NESTED) {
            $t = $t->child('z')->child($name)->child( $version // 'v1' )->child('deadbeef');
            $t->child('include')->mkpath;
            $t->child('lib')->mkpath;
            $t->child('bin')->mkpath;
        }
        $t->child('include')->child("$name.h")->spew_utf8("#define $name 1\n");
        $t->child('lib')->child("$name.lib")->spew_utf8("LIB\n");
        $t->child('bin')->child("$name.dll")->spew_utf8("BIN\n");
        return 1;
    }

    method add_repo ( $name, $url ) {
        push @$calls,          { action => 'add_repo', name => $name, url => $url };
        push @main::ALL_CALLS, { action => 'add_repo', name => $name, url => $url };
    }

    method _pkg ( $name, $version ) {
        Alien::Xrepo::PackageInfo->new(
            includedirs => ["$store/$name/include"],
            libfiles    => ["$store/$name/bin/$name.dll"],
            license     => undef,
            linkdirs    => ["$store/$name/lib"],
            links       => [$name],
            shared      => 1,
            static      => 0,
            version     => $version // '1.2.3',
            installdir  => "$store/$name",
            kind        => 'library'
        );
    }
}

sub sf ( $packages, %opts ) {
    my $text = "use alienfile;\nplugin 'Build::Xrepo' => (\n  packages => $packages,\n";
    $text .= "  ffi         => $opts{ffi},\n"                                                           if $opts{ffi};
    $text .= "  version     => '$opts{version}',\n"                                                     if $opts{version};
    $text .= "  kind        => '$opts{kind}',\n"                                                        if $opts{kind};
    $text .= "  local_repos => [" . join( ', ', map {qq{"$_"}} @{ $opts{local_repos} // [] } ) . "],\n" if $opts{local_repos};
    $text .= "  repo        => 'Alien::Build::Plugin::Build::Xrepo::TestSpy',\n";
    $text .= ");\n";
    return $text;
}

sub driven_build ($text) {
    my $dir   = tempdir( CLEANUP => 1 );
    my $build = alienfile_ok( $text, stage => "$dir/stage", prefix => "$dir/prefix", root => "$dir/root" );
    return { dir => $dir, build => $build } unless $build;
    ok $build, 'alienfile compiles';
    is $build->probe, 'share', 'probe ends in a share install';
    $build->download;
    $build->build;
    return { dir => $dir, build => $build };
}
sub winslash { my $s = shift; $s =~ s{\\}{/}g; $s }
#
subtest 'share install assembles and gathers a single package' => sub {
    my $r     = driven_build( sf("['zstd']") );
    my $build = $r->{build};
    my $dir   = $r->{dir};
    my $rp    = $build->runtime_prop;
    is $rp->{install_type}, 'share', 'install_type recorded';
    my $cflags = winslash( $rp->{cflags} );
    like $cflags, qr/-I[^\s]*zstd\/include/, 'primary include flags present';
    my $pfx = winslash( $rp->{prefix} );
    like $cflags, qr{\Q$pfx\E}, 'flags reference the final prefix';
    my $libs = winslash( $rp->{libs} );
    like $libs, qr[-L[^\s]*zstd\/lib],   'primary lib flags present';
    like $libs, qr[zstd\.lib\b|\-lzstd], 'primary link flags present';
    is $rp->{version}, '1.2.3', 'version gathered';
    ok -e "$build->{install_prop}{prefix}/zstd/include/zstd.h", 'package tree copied into the stage';
    ok -e "$build->{install_prop}{prefix}/bin/zstd.dll",        'bin dir merged into stage/bin';
    my $bins = [ map { winslash($_) } @{ $rp->{bin_dir} } ];
    is $bins, ["$pfx/zstd/bin"], 'bin_dir re-rooted to the final prefix';
    my $it = $build->meta->interpolator;
    ok $it->has_helper('xrepo'),              'xrepo helper registered';
    ok $it->has_helper('xmake'),              'xmake helper registered';
    ok $it->has_helper('xrepo_cflags'),       'xrepo_cflags helper registered';
    ok $it->has_helper('xrepo_libs'),         'xrepo_libs helper registered';
    ok $it->has_helper('xrepo_version'),      'xrepo_version helper registered';
    ok $it->has_helper('xrepo_dynamic_libs'), 'xrepo_dynamic_libs helper registered';
    like $it->interpolate( '%{xrepo_version}', $build ), qr[1\.2\.3], 'helper reads runtime props';
};
subtest 'multi-package recipe populates alt with the ambient profile' => sub {
    my $r     = driven_build( sf( "['zstd', { name => 'libsdl3', kind => 'shared' }]", version => '3.14.0' ) );
    my $build = $r->{build};
    my $rp    = $build->runtime_prop;
    like winslash( $rp->{cflags} ),             qr/-I[^\s]*zstd\/include/, 'primary cflags set';
    like winslash( $rp->{alt}{libsdl3}{libs} ), qr[zstd|libsdl3],          'alt libs present';
    is $rp->{alt}{libsdl3}{version}, '3.14.0', 'ambient version folded into the alt package';
    ok !exists $rp->{alt}{zstd}, 'primary package is not duplicated in alt';
};
subtest 'failure of a sibling isolates the gather' => sub {
    $Alien::Build::Plugin::Build::Xrepo::TestSpy::FAIL{libsdl3} = 1;
    my $r     = driven_build( sf("['zstd', { name => 'libsdl3' }, 'ninja']") );
    my $build = $r->{build};
    my $rp    = $build->runtime_prop;
    delete $Alien::Build::Plugin::Build::Xrepo::TestSpy::FAIL{libsdl3};
    my $errors = $build->install_prop->{xrepo}{errors};
    like $errors->{libsdl3},     qr/boom/, 'failed sibling recorded in errors';
    like $rp->{errors}{libsdl3}, qr/boom/, 'failure flagged in the returned runtime_prop';
    ok !exists $rp->{errors}{zstd}, 'successful packages are not flagged';
    like winslash( $rp->{cflags} ), qr/-I[^\s]*zstd\/include/, 'primary package still gathered';
    ok exists $rp->{alt}{ninja},    'sibling after the failure gathered in alt';
    ok !exists $rp->{alt}{libsdl3}, 'failed sibling omitted from alt';
    is $build->install_type, 'share', 'a partial success is still a share install';
    my $mf = path( $build->install_prop->{xrepo}{download_dir} )->child('xrepo.manifest');
    ok -e $mf, 'xrepo.manifest written';
    my $m = $mf->slurp_utf8;
    like $m,   qr[^zstd$]m,    'manifest lists the installed package';
    like $m,   qr[^ninja$]m,   'manifest lists the surviving sibling';
    unlike $m, qr[^libsdl3$]m, 'manifest omits the failed package';
};
subtest 'ffi gathers a name and dynamic libs' => sub {
    my $r     = driven_build( sf( "['zstd']", ffi => 1 ) );
    my $build = $r->{build};
    my $rp    = $build->runtime_prop;
    is $rp->{ffi_name}, 'zstd', 'ffi_name from the primary links';
    ok scalar @{ $rp->{dynamic_libs} } >= 1,               'dynamic libs listed';
    ok scalar grep {/zstd\.dll/} @{ $rp->{dynamic_libs} }, 'dynamic libs name the package dll';
};
subtest 'probe records per-package satisfaction from the engine' => sub {
    my $r     = driven_build( sf("['zstd']") );
    my $build = $r->{build};
    my $probe = $build->install_prop->{xrepo}{probed}{zstd};
    ok defined $probe, 'probe ran and populated install_prop';
    is $probe->{satisfied}, 0,     'spy reported no store hit, so not satisfied';
    is $probe->{version},   undef, 'no version found for an uninstalled package';
};
subtest 'nested xrepo export layout is flattened into the prefix' => sub {
    $main::NESTED = 1;
    my $r = driven_build( sf("['zstd']") );
    $main::NESTED = 0;
    my $build = $r->{build};
    my $stage = $build->install_prop->{prefix};
    ok -e "$stage/zstd/include/zstd.h", 'include flattened from the nested content dir';
    ok -e "$stage/zstd/lib/zstd.lib",   'lib flattened';
    ok -e "$stage/zstd/bin/zstd.dll",   'bin flattened';
    ok -e "$stage/bin/zstd.dll",        'bin merged into stage/bin';
    my $rp = $build->runtime_prop;
    like winslash( $rp->{cflags} ), qr/-I[^\s]*zstd\/include/, 'cflags point at the flattened include dir';
};
subtest 'local_repos are registered with the engine' => sub {
    my $lr = Path::Tiny->tempdir;
    $lr->child('packages')->mkpath;
    @main::ALL_CALLS = ();
    my $build = driven_build( sf( "['zstd']", local_repos => [$lr] ) )->{build};
    my @repos = map { $_->{url} } grep { $_->{action} eq 'add_repo' } @main::ALL_CALLS;
    like "@repos", qr/\Q$lr\E/, 'local repo path passed to the engine add_repo';
    is scalar @repos, 1, 'exactly one repo registered';
};
subtest 'missing packages is rejected at alienfile compile' => sub {
    my $dir = Path::Tiny->tempdir;
    like dies {
        alienfile( source => "use alienfile;\nplugin 'Build::Xrepo';\n", stage => "$dir/stage", prefix => "$dir/prefix", root => "$dir/root" );
    }, qr[packages], 'packages is a required property';
};
subtest 'interpolate helpers read their own build, not a shared global' => sub {
    my $a  = driven_build( sf( "['zstd']",  version => '1.2.3' ) );
    my $b  = driven_build( sf( "['ninja']", version => '9.9.9' ) );
    my $ia = $a->{build}->meta->interpolator;
    my $ib = $b->{build}->meta->interpolator;
    like $ia->interpolate( '%{xrepo_version}', $a->{build} ), qr[1\.2\.3], 'A helper sees version from its own build';
    like $ib->interpolate( '%{xrepo_version}', $b->{build} ), qr[9\.9\.9], 'B helper sees version from its own build';
    is $ia->interpolate( '%{xrepo_cflags}', $a->{build} ), $a->{build}->runtime_prop->{cflags}, 'A helper sees cflags from its own build';
    is $ib->interpolate( '%{xrepo_cflags}', $b->{build} ), $b->{build}->runtime_prop->{cflags}, 'B helper sees cflags from its own build';
};
#
done_testing;
