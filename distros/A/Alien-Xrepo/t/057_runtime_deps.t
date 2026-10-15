use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp qw[tempdir];
use JSON::PP   qw[encode_json];
use Path::Tiny;
use Alien::Xrepo;
use Alien::Xrepo::Runtime;
use experimental 'class';
my $dir = tempdir( CLEANUP => 1 );

# The runtime-dependency diagnostic classifies each shared-library dependency by where the loader would find
# it. The real scan shells out to xmake, so stub just that step and feed a known raw list; everything else
# (path classification, the Windows/ELF/Mach-O system-name heuristics) runs for real.
subtest 'Alien::Xrepo::runtime_deps classifies store / host / system / unresolved' => sub {
    no warnings 'redefine';
    my $store = path( $dir, 'store', 'foo' )->stringify;
    my $other = path( $dir, 'elsewhere' )->stringify;

    # A bare name the OS provides, and one it does not.
    my $sysname = $^O eq 'MSWin32' ? 'KERNEL32.dll' : 'libc.so.6';
    my $bare    = $^O eq 'MSWin32' ? 'iguana.dll'   : 'libiguana.so.1';

    # A path inside a real system directory, so the "system dir" branch is exercised on this OS.
    my $r0       = Alien::Xrepo->new;
    my @sysdir   = $r0->_system_lib_dirs;
    my $sysbase  = 'libprobeprobe.so';
    my $syslib   = @sysdir ? path( $sysdir[0], $sysbase )->stringify : undef;
    my $storelib = path( $store, 'lib', 'libbar.6.dylib' )->stringify;
    my $hostlib  = path( $other, 'lib', 'libbaz.so' )->stringify;
    my @raw      = ( $sysname, $bare, $storelib, $hostlib );
    push @raw, $syslib if defined $syslib;
    local *Alien::Xrepo::scan_runtime_deps = sub { return @raw };
    my $r     = Alien::Xrepo->new;
    my $deps  = $r->runtime_deps( 'ignored', search_dirs => [ path( $store, 'lib' )->stringify ], store_dirs => [$store] );
    my %scope = map { $_->{name} => $_->{scope} } @$deps;
    is $scope{$sysname},         'system',     'a bare OS-provided loader name stays system';
    is $scope{$bare},            'unresolved', 'a bare non-system loader name is unresolved';
    is $scope{'libbar.6.dylib'}, 'store',      'a resolved path under a store dir is store';
    is $scope{'libbaz.so'},      'host',       'a resolved path elsewhere on the host is host';
    is $scope{$sysbase},         'system',     'a resolved path under a real system dir is system' if defined $syslib;
    is scalar(@$deps),           scalar(@raw), 'every raw entry is classified';
};

# A spy engine that supplies a real libpath (so the -f guard passes) and canned classified deps, so the
# Runtime wrapper's gathering / caching / report / package_info wiring can be checked without xmake.
class Alien::Xrepo::Runtime::TestDepsSpy {
    field $libpath : param  = undef;
    field $scans   : reader = 0;

    method fetch ( $name, $version, %opts ) {
        return Alien::Xrepo::PackageInfo->new(
            includedirs => ["C:/store/$name/include"],
            libfiles    => [],
            license     => undef,
            linkdirs    => ["C:/store/$name/lib"],
            links       => [$name],
            shared      => 1,
            static      => 0,
            version     => $version // '9.9.9',
            libpath     => $libpath // "/nonexistent/$name.dll",
            bindirs     => ["C:/store/$name/bin"],
            installdir  => "C:/store/$name",
            kind        => 'library'
        );
    }

    method fetch_closure ( $name, $version, %opts ) {
        return (
            {   artifacts => { installdir => "C:/store/$name" },
                libfiles  => [],
                linkdirs  => ["C:/store/$name/lib"],
                bindirs   => ["C:/store/$name/bin"]
            }
        );
    }

    method runtime_deps ( $libpath, %opts ) {
        $scans++;
        return [
            { name => 'libdep.so',    path  => '/vendor/lib/libdep.so', dir => '/vendor/lib', scope => 'store' },
            { name => 'KERNEL32.dll', scope => 'system' }
        ];
    }
    method loader_env_var {'LD_LIBRARY_PATH'}
}

# A plain spy: fetch only, no closure/runtime_deps/loader_env_var, to prove the wrapper degrades gracefully.
class Alien::Xrepo::Runtime::TestPlainSpy {

    method fetch ( $name, $version, %opts ) {
        return Alien::Xrepo::PackageInfo->new(
            includedirs => ["C:/store/$name/include"],
            libfiles    => ["C:/store/$name/bin/$name.dll"],
            license     => undef,
            linkdirs    => ["C:/store/$name/lib"],
            links       => [$name],
            shared      => 1,
            static      => 0,
            version     => $version // '9.9.9',
            libpath     => "C:/store/$name/bin/$name.dll",
            bindirs     => ["C:/store/$name/bin"],
            installdir  => "C:/store/$name",
            kind        => 'library'
        );
    }
}

class Alien::Xrepo::Runtime::TestDepsDyn : isa(Alien::Xrepo::Runtime) {
    method pkg_name {'zstd'}
}
subtest 'Runtime::runtime_deps gathers, caches and reports the diagnostic' => sub {
    my $lib  = path( $dir, 'libzstd.dylib' )->spew('not a real library');
    my $spy  = Alien::Xrepo::Runtime::TestDepsSpy->new( libpath => $lib->stringify );
    my $a    = Alien::Xrepo::Runtime::TestDepsDyn->new( repo    => $spy );
    my $deps = $a->runtime_deps;
    is scalar(@$deps), 2, 'two dependencies discovered';
    is $spy->scans,    1, 'one scan';
    $a->runtime_deps;
    is $spy->scans,                                     1,                 'subsequent access is cached';
    is [ map { $_->{name} } $a->foreign_runtime_deps ], ['libdep.so'],     'only the non-system dep is foreign';
    is [ $a->runtime_dep_dirs ],                        ['/vendor/lib'],   'the foreign dep directory is reported';
    is $a->loader_env_var,                              'LD_LIBRARY_PATH', 'loader env var from the engine';
    like $a->runtime_dep_report,   qr/libdep\.so \[store\]/, 'report names the dep and its scope';
    unlike $a->runtime_dep_report, qr/KERNEL32/,             'report omits system libraries';
    my $pi = $a->package_info;
    is scalar( @{ $pi->runtime_deps } ), 2, 'package_info carries the runtime deps';
    ok $pi->with_runtime_deps( [] ) == $pi, 'already-attached info is returned unchanged';
};
subtest 'snapshot runtime_deps paths are rebased like other paths' => sub {
    my $share = path( $dir, 'share-snap' )->mkdir;
    my $snap  = $share->child('xrepo-snapshot.json');
    $snap->spew_utf8(
        encode_json(
            {   dist_name    => 'Exotic-Z',
                install_type => 'share',
                packages     => {
                    zstd => {
                        includedirs  => ['zstd/include'],
                        libfiles     => [],
                        license      => undef,
                        linkdirs     => ['zstd/lib'],
                        links        => ['zstd'],
                        shared       => 1,
                        static       => 0,
                        version      => '1.5.6',
                        libpath      => 'zstd/bin/zstd.dll',
                        bindirs      => ['zstd/bin'],
                        installdir   => 'zstd',
                        kind         => 'library',
                        runtime_deps => [ { name => 'libdep.so', path => 'zstd/lib/libdep.so', dir => 'zstd/lib', scope => 'store' }, ],
                    }
                }
            }
        )
    );
    my $a = Alien::Xrepo::Runtime->new(
        pkg_name            => 'zstd',
        snapshot            => $snap,
        repo                => Alien::Xrepo::Runtime::TestPlainSpy->new,
        autodetect_snapshot => 0
    );
    my $dep = $a->package_info->runtime_deps->[0];
    is $dep->{path},  path( $share, 'zstd', 'lib', 'libdep.so' )->stringify, 'runtime_dep path rebased against the snapshot dir';
    is $dep->{dir},   path( $share, 'zstd', 'lib' )->stringify,              'runtime_dep dir rebased against the snapshot dir';
    is $dep->{scope}, 'store',                                               'scope preserved through the rebase';
};
subtest 'package_info degrades when the engine cannot scan' => sub {
    my $spy = Alien::Xrepo::Runtime::TestPlainSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => 'zstd', repo => $spy );
    my $pi  = $a->package_info;
    is $pi->runtime_deps, [], 'no diagnostic from an engine that cannot scan';
    is $a->runtime_deps,  [], 'runtime_deps degrades to empty';
    is $a->loader_env_var, ( $^O eq 'MSWin32' ? 'PATH' : $^O eq 'darwin' ? 'DYLD_LIBRARY_PATH' : 'LD_LIBRARY_PATH' ),
        'loader env var falls back to the platform default';
};
#
done_testing;
