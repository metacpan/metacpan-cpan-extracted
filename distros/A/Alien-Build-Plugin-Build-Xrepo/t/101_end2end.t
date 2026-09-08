use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test::Alien::Build qw[alienfile_ok alien_build_ok alien_install_type_is];
use Test::Alien        qw[alien_ok ffi_ok with_subtest];
use Path::Tiny;
use File::Spec;

# Alien::Build unshifts bin_dir / pkg_config entries into tied @PATH /
# @PKG_CONFIG_PATH for every hook; under `-w`/PERL5OPT=-w an undefined variable
# makes Env::UNSHIFT spam "Use of uninitialized value in split".  Define both.
$ENV{PATH}            = '' unless defined $ENV{PATH};
$ENV{PKG_CONFIG_PATH} = '' unless defined $ENV{PKG_CONFIG_PATH};

# End-to-end consumer test.  Unlike t/14_build_plugin.t (which drives the plugin
# against a spy engine), this runs the plugin against the REAL Alien::Xrepo engine
# and real xrepo installs, then consumes the result through the Alien::Base facade
# that alien_build_ok builds.  Proves the whole stack: alienfile -> plugin ->
# engine -> xrepo -> Alien::Base consumer -> FFI::Platypus.
#
# libpng is used because it ships a real shared DLL on Windows (png.dll), which
# the gather_ffi hook must surface so FFI can load and call a symbol.
#
# Aliens pull real packages with real network, so guard on xrepo actually being
# present before we attempt anything.
my $xrepo = eval { require Alien::Xmake; Alien::Xmake->new->xrepo } // 'xrepo';
my $ok    = File::Spec->file_name_is_absolute($xrepo) ? ( -e $xrepo ) : _which_in_path($xrepo);
plan skip_all => "xrepo not available ($xrepo)" unless $ok;
my $build = alienfile_ok <<'ALIENFILE';
use alienfile;
plugin 'Build::Xrepo' => (
    packages => [{ name => 'zlib', kind => 'shared' }],
    ffi      => 1
);
ALIENFILE
$build || die 'alienfile did not compile';
alien_install_type_is 'share', 'xrepo install is a share install';
my $alien = alien_build_ok 'plugin built and wrapped by Alien::Base';
$alien || die 'alien build failed';
alien_ok $alien;
subtest 'consumer flags and dirs' => sub {
    my @dyn = $alien->dynamic_libs;
    ok scalar @dyn >= 1, 'dynamic libs found';
    like $alien->cflags, qr[-I], 'cflags present';
    like $alien->libs,   qr[-L], 'libs present';
};

# The capstone FFI check: load the dynamic libs the plugin gathered and call a real exported symbol
# to prove the whole chain down to the native library works.
ffi_ok with_subtest {
    my ($ffi) = @_;
    my $func  = $ffi->function( zlibVersion => [] => 'string' );
    my $v     = $func->call;
    ok defined $v && length $v, 'zlibVersion called via gathered dynamic_libs: ' . ( $v // '(undef)' );
    like $v, qr[^\d+\.\d+\.\d+], 'zlibVersion returned a semver string';
};
#
done_testing;

sub _which_in_path ($exec) {
    my $sep  = ( $^O eq 'MSWin32' ) ? ';'                : ':';
    my @exts = ( $^O eq 'MSWin32' ) ? qw(.exe .bat .cmd) : ('');
    for my $dir ( split /\Q$sep\E/, $ENV{PATH} ) {
        next if !length $dir;
        for my $ext (@exts) {
            my $cand = File::Spec->catfile( $dir, "$exec$ext" );
            return $cand if -e $cand && !-d $cand;
        }
    }
    return undef;
}
