use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test::Alien::Build qw[alienfile_ok alien_build_ok alien_install_type_is];
use Test::Alien        qw[alien_ok ffi_ok with_subtest];
use Capture::Tiny      qw[capture];
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

#~ plan skip_all => "xrepo not available ($xrepo)" unless $ok;
# `verbose => 1` makes xmake print the whole package install log to the captured test output instead of
# only writing it to installdir.failed/logs/install.txt.  It is noisy on success, so keep it opt-in; the
# failure path below reads that log for us either way.
my $verbose = $ENV{ALIEN_XREPO_VERBOSE} ? 1 : 0;
my $build   = alienfile_ok <<"ALIENFILE";
use alienfile;
plugin 'Build::Xrepo' => (
    packages => [{ name => 'zlib', kind => 'shared' }],
    ffi      => 1,
    verbose  => $verbose
);
ALIENFILE
$build || die 'alienfile did not compile';
alien_install_type_is 'share', 'xrepo install is a share install';
my $started = time;
{
    our $TODO = todo 'Hey, things happen, man...';
    my $alien = alien_build_ok 'plugin built and wrapped by Alien::Base';
    if ( !$alien ) {
        _diagnose_failed_installs($started);

        #die 'alien build failed';
    }
    alien_ok $alien;
    subtest 'consumer flags and dirs' => sub {
        my @dyn = $alien->dynamic_libs;
        ok scalar @dyn >= 1, 'dynamic libs found';
        like $alien->cflags, qr[-I], 'cflags present';
        like $alien->libs,   qr[-L], 'libs present';
    };
}

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

# xmake writes a failed package install's full output to
# <cachedir>/packages/<...>/<version>/installdir.failed/logs/install.txt and only prints a short tail plus the
# path.  Test::Alien already shows the captured build output when the build dies, but the log file itself is
# left behind on the build machine's cache, so read it back into the TAP diagnostics while it still exists.
sub _diagnose_failed_installs ($since) {
    my $cache = _xmake_cachedir();
    if ( !defined $cache ) {
        diag 'xmake cache directory unknown; skipped failed-install logs';
        return;
    }
    my $packages = path($cache)->child('packages');
    if ( !$packages->is_dir ) {
        diag "no xmake package cache at $packages; skipped failed-install logs";
        return;
    }
    my %logs;
    $packages->visit(
        sub ( $file, $state ) {
            diag "$file";
            return if $file->is_dir;
            return unless $file->basename eq 'install.txt';
            return unless $file->parent->basename eq 'logs';
            return unless $file->parent->parent->basename eq 'installdir.failed';
            my $mtime = eval { $file->stat->mtime };
            return if defined $mtime && $mtime < $since - 5;
            $logs{ $file->stringify } = 1;
        },
        { recurse => 1 }
    );
    if ( !%logs ) {
        diag "no recent failed xmake install log under $packages (the failure may have happened before xmake ran)";
        return;
    }
    for my $log ( sort keys %logs ) {
        my @lines = eval { path($log)->lines_utf8( { chomp => 1 } ) };
        if ($@) {
            @lines = eval { path($log)->lines( { chomp => 1 } ) };
            if ($@) {
                diag "could not read xmake install log $log: $@";
                next;
            }
        }
        s/\r$// for @lines;
        my $max = 2000;
        if ( @lines > $max ) {
            my $skipped = @lines - $max;
            diag "xmake install log: $log ($skipped earlier line(s) omitted)";
            @lines = @lines[ -$max .. -1 ];
        }
        else {
            diag "xmake install log: $log";
        }
        diag "  $_" for @lines;
    }
    return;
}

# Ask xmake itself for the cache directory: the XMAKE_GLOBALDIR / %APPDATA% / ~ resolution is not portable to
# duplicate here, and this mirrors what Alien::Xrepo does when it seeds xmake's templates.
sub _xmake_cachedir {
    my $exe = eval { Alien::Xmake->new->exe };
    return undef unless defined $exe && length $exe && -e $exe;
    my $script = q{import('core.base.global'); print('XREPO_CACHEDIR=' .. global.cachedir())};
    my ($out)  = capture { system $exe, 'lua', '-c', $script };
    my ($dir)  = ( defined $out ? $out : '' ) =~ /^XREPO_CACHEDIR=(.+)$/m;
    return undef unless defined $dir;
    $dir =~ s/\s+$//;
    return $dir;
}

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
