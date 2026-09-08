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
subtest 'hermetic snapshot: no xrepo call at all' => sub {
    my $snap = path($dir)->child('snapshot.json');
    $snap->spew_utf8(
        encode_json(
            {   dist_name    => 'Alien-Zstandard',
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
    is $a->version,      '1.5.6',                     'snapshot version served';
    is $a->cflags,       '-IC:/snap/zstd/include',    'snapshot cflags served';
    is $a->libpath,      'C:/snap/zstd/bin/zstd.dll', 'snapshot libpath served';
    is $a->install_type, 'share',                     'snapshot install_type served';
    is $spy->calls,      0,                           'no xrepo subprocess in hermetic mode';
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
#
done_testing;
