use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp qw[tempdir];
use JSON::PP   qw[encode_json];
use Path::Tiny;
use Config;
use Alien::Xrepo;
use Alien::Xrepo::Runtime;
use Alien::Xrepo::Build::Recipe;
use experimental 'class';

# A spy engine whose fetch serves canned PackageInfo and counts calls, so the
# laziness/caching of the runtime layer can be verified without xrepo.
class Alien::Xrepo::Runtime::TestSpy {
    field $calls : reader = 0;

    method fetch ( $name, $version, %opts ) {
        $calls++;
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

class Alien::Xrepo::Runtime::TestDyn : isa(Alien::Xrepo::Runtime) {
    method pkg_name {'zstd'}
}

# A spy that records the opts each fetch was called with, so recipe defaults
# flowing into dynamic resolution can be checked.
class Alien::Xrepo::Runtime::TestOpts : isa(Alien::Xrepo::Runtime::TestSpy) {
    field $seen = [];
    method seen {$seen}

    method fetch ( $name, $version, %opts ) {
        push @$seen, { name => $name, opts => {%opts} };
        $self->SUPER::fetch( $name, $version, %opts );
    }
}

# The single-source pattern: the whole dist description (name, packages,
# defaults, local_repos) lives in one subclass method.
class Alien::Xrepo::Runtime::TestFull : isa(Alien::Xrepo::Runtime) {

    method recipe {
        return {
            name        => 'Alien-TestFull',
            packages    => [ { name => 'zstd', version => '1.5.6', kind => 'shared' }, 'libsdl3' ],
            defaults    => { mode => 'release' },
            local_repos => ['vendor/recipes'],
        };
    }
}

# Declares both; recipe() must win.
class Alien::Xrepo::Runtime::TestBoth : isa(Alien::Xrepo::Runtime) {
    method recipe   { return { packages => ['zstd'] }; }
    method pkg_name {'libsdl3'}
}
my $dir = tempdir( CLEANUP => 1 );
subtest 'dynamic mode: subclass declares pkg_name, fetch is lazy and cached' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime::TestDyn->new( repo => $spy );
    is [ $a->package_names ], ['zstd'],                  'pkg_name fallback read from subclass method';
    is $a->version,           '9.9.9',                   'version defaults to store';
    is $a->cflags,            '-IC:/store/zstd/include', 'cflags from includedirs';
    like $a->libs,    qr/-LC:.*\/zstd\/lib/, 'libs from linkdirs/links';
    like $a->libpath, qr/zstd\.dll/,         'libpath is the runtime library';
    is scalar @{ [ $a->bin_dir ] }, 1, 'bin_dir list';
    like $a->dist_dir, qr/zstd/, 'dist_dir is the install root';
    is $a->install_type, 'share', 'a fetchable package is a share install';
    is $spy->calls,      1,       'all accessors shared one fetch';
    $a->cflags;
    $a->libs;
    is $spy->calls, 1, 'second access is cached';
};
subtest 'per-package defs and install_opts reach the fetch' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new(
        pkg_name     => [ { name => 'zstd', version => '1.5.6', kind => 'shared', configs => { legacy => 1 } } ],
        install_opts => { mode => 'release' },
        repo         => $spy,
    );
    $a->version;
    is $spy->calls, 1,       'one fetch happened';
    is $a->version, '1.5.6', 'per-package version honored';
};
subtest 'multi-package alt() pins accessors to a package' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => [ 'zstd', 'libsdl3' ], repo => $spy );
    my $alt = $a->alt('libsdl3');
    like $alt->cflags, qr/libsdl3/, 'alt accessors pinned to libsdl3';
    like $a->cflags,   qr/zstd/,    'primary accessors stay on zstd';
    ok $a->alt eq $a, 'alt of the primary returns self';
    like dies { $a->alt('nope') }, qr/Unknown package/, 'alt of an unknown package dies';
};
subtest 'bin_dir / prepend_to_path put a shipped tool on PATH' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => 'ninja', repo => $spy );
    is [ $a->bin_dir ], ['C:/store/ninja/bin'], 'bin_dir exposes the tool dir';
    {
        local $ENV{PATH} = 'C:/original';
        my @dirs = $a->prepend_to_path;
        is [@dirs],    ['C:/store/ninja/bin'],                                                 'prepend_to_path returns the bindirs';
        is $ENV{PATH}, join( $Config::Config{path_sep}, 'C:/store/ninja/bin', 'C:/original' ), 'bindir prepended to PATH';
    }
    my $spy2 = Alien::Xrepo::Runtime::TestSpy->new;
    my $alt  = Alien::Xrepo::Runtime->new( pkg_name => [ 'zstd', 'ninja' ], repo => $spy2 )->alt('ninja');
    {
        local $ENV{PATH} = 'C:/original';
        $alt->prepend_to_path;
        is $ENV{PATH}, join( $Config::Config{path_sep}, 'C:/store/ninja/bin', 'C:/original' ), 'alt view prepends the pinned package bindir';
    }
};
subtest 'hermetic snapshot: no xrepo call at all' => sub {
    my $snap = path($dir)->child('snapshot.json');
    $snap->spew_utf8(
        encode_json(
            {   dist_name    => 'Exotic-Zstandard',
                install_type => 'share',
                packages     => {
                    zstd => {
                        includedirs => ['C:/snap/zstd/include'],
                        libfiles    => ['C:/snap/zstd/bin/zstd.dll'],
                        license     => undef,
                        linkdirs    => ['C:/snap/zstd/lib'],
                        links       => ['zstd'],
                        shared      => 1,
                        static      => 0,
                        version     => '1.5.6',
                        libpath     => 'C:/snap/zstd/bin/zstd.dll',
                        bindirs     => ['C:/snap/zstd/bin'],
                        installdir  => 'C:/snap/zstd',
                        kind        => 'library'
                    }
                }
            }
        )
    );
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => 'zstd', snapshot => $snap, repo => $spy, autodetect_snapshot => 0 );
    is $a->version, '1.5.6', 'snapshot version served';
    like $a->cflags,  qr[C:/snap/zstd/include$],       'snapshot cflags served';
    like $a->libpath, qr[C:/snap/zstd/bin/zstd\.dll$], 'snapshot libpath served';
    is $a->install_type, 'share', 'snapshot install_type served';
    is $spy->calls,      0,       'no xrepo subprocess in hermetic mode';
};
subtest 'unknown packages rejected on use' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => 'zstd', repo => $spy );
    like dies { $a->libpath('nope') }, qr/Unknown package/, 'unknown package name dies on access';
};
subtest 'snapshot autodetect keys to the Alien-<tail> share dir' => sub {
    my @cand = Alien::Xrepo::Runtime->_snapshot_candidates_for('Alien::Xrepo::Runtime::Nope');
    is scalar(@cand), 1, 'one candidate when no installed share dir';
    like $cand[0], qr/Alien-Xrepo-Runtime-Nope[\\\/]xrepo-snapshot\.json$/, 'candidate keys to Alien-<tail> share dir';
};
subtest 'snapshot autodetect keys to the Exotic-<tail> share dir too' => sub {
    my @cand = Alien::Xrepo::Runtime->_snapshot_candidates_for('Exotic::Zlib');
    is scalar(@cand), 1, 'one candidate when no installed share dir';
    like $cand[0], qr/Exotic-Zlib[\\\/]xrepo-snapshot\.json$/, 'candidate keys to Exotic-<tail> share dir';
};
subtest 'snapshot autodetect never invents an Alien- prefix' => sub {
    my @cand = Alien::Xrepo::Runtime->_snapshot_candidates_for('Sanko::Thing');
    is scalar(@cand), 1, 'one candidate when no installed share dir';
    like $cand[0], qr/Sanko-Thing[\\\/]xrepo-snapshot\.json$/, 'candidate keys to the bare module tail';
};
subtest 'subclass recipe() is the single declaration for dist and engine' => sub {
    my $spy = Alien::Xrepo::Runtime::TestOpts->new;
    my $a   = Alien::Xrepo::Runtime::TestFull->new( repo => $spy );
    is [ $a->package_names ],          [ 'zstd', 'libsdl3' ], 'packages read from subclass recipe()';
    is $a->package_defs->{zstd}{kind}, 'shared',              'per-package def honored';
    is $a->version,                    '1.5.6',               'per-package version honored';
    like $a->libpath, qr/zstd\.dll/, 'resolution works';
    is $spy->seen->[0]{opts}{mode}, 'release', 'recipe defaults folded into fetch opts';
    $a->libpath('libsdl3');
    is $spy->calls, 2, 'each package fetched once';
};
subtest 'subclass recipe() wins over pkg_name()' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime::TestBoth->new( repo => $spy );
    is [ $a->package_names ], ['zstd'], 'recipe() preferred over pkg_name()';
};
subtest 'constructor accepts an inline hashref recipe' => sub {
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( recipe => { packages => ['zstd'], defaults => { kind => 'shared' } }, repo => $spy, );
    like $a->cflags, qr/zstd/, 'hashref recipe resolved dynamically';
    is $a->install_type, 'share', 'resolvable package is a share install';
};
subtest 'constructor accepts an Alien::Xrepo::Build::Recipe object' => sub {
    my $rec = Alien::Xrepo::Build::Recipe->new( packages => ['zstd'] );
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( recipe => $rec, repo => $spy );
    is [ $a->package_names ], ['zstd'], 'Recipe object honored';
};
subtest 'hermetic snapshot rebases share-relative paths against its own dir' => sub {
    my $share = path($dir)->child('share');
    $share->child('zstd')->mkpath;
    my $snap = $share->child('xrepo-snapshot.json');
    $snap->spew_utf8(
        encode_json(
            {   dist_name    => 'Exotic-Zstandard',
                install_type => 'share',
                packages     => {
                    zstd => {
                        includedirs => ['zstd/include'],
                        libfiles    => [],
                        license     => undef,
                        linkdirs    => ['zstd/lib'],
                        links       => ['zstd'],
                        shared      => 1,
                        static      => 0,
                        version     => '1.5.6',
                        libpath     => 'zstd/bin/zstd.dll',
                        bindirs     => ['zstd/bin'],
                        installdir  => 'zstd',
                        kind        => 'library'
                    }
                }
            }
        )
    );
    my $spy = Alien::Xrepo::Runtime::TestSpy->new;
    my $a   = Alien::Xrepo::Runtime->new( pkg_name => 'zstd', snapshot => $snap, repo => $spy, autodetect_snapshot => 0 );
    is $a->version, '1.5.6',                                                     'snapshot version served';
    is $a->libpath, path($share)->child( 'zstd', 'bin', 'zstd.dll' )->stringify, 'relative libpath rebased against snapshot dir';
    is $a->cflags,  '-I' . path($share)->child( 'zstd', 'include' )->stringify,  'relative includedirs rebased';
    like $a->libs, qr/zstd[\\\/]lib/, 'relative linkdirs rebased';
    is $a->dist_dir,     path($share)->child('zstd')->stringify, 'relative installdir rebased';
    is $a->install_type, 'share',                                'snapshot install_type served';
    is $spy->calls,      0,                                      'pure rebase, no xrepo call';
};
#
done_testing;
