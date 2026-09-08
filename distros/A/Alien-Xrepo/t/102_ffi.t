use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Path::Tiny qw[path];
use File::Temp qw[tempdir];
use Alien::Xrepo;
#
my $tmp  = path( tempdir() );
my $repo = Alien::Xrepo->new( root => $tmp, verbose => 0, kind => 'shared' );
my $zlib = $repo->install('zlib');
ok defined $zlib, 'Installed zlib';
my $lib_path = $zlib->libpath;
diag 'zlib libpath: ' . ( $lib_path // '(none)' );
skip_all 'zlib has no usable shared library for FFI wrapping' unless defined $lib_path && -e $lib_path;
#
subtest Affix => sub {
    skip_all 'Affix is not installed' unless eval { require Affix; 1; };
    Affix::affix( $lib_path, [ zlibVersion => 'a_zlibVersion' ], [] => Affix::String() );
    my $v = a_zlibVersion();
    ok defined $v && length $v, 'Affix bound and called zlibVersion: ' . ( $v // '(undef)' );
    like $v, qr{^\d+\.\d+\.\d+}, 'zlibVersion returned a semver-ish string';
};
subtest 'FFI::Platypus' => sub {
    skip_all 'FFI::Platypus is not installed' unless eval { require FFI::Platypus; 1; };
    my $plat = FFI::Platypus->new( api => 2 );
    $plat->lib($lib_path);
    $plat->attach( [ zlibVersion => 'p_zlibVersion' ] => [] => 'string' );
    my $v = p_zlibVersion();
    ok defined $v && length $v, 'Platypus bound and called zlibVersion: ' . ( $v // '(undef)' );
    like $v, qr{^\d+\.\d+\.\d+}, 'zlibVersion returned a semver-ish string';
};
#
done_testing;
