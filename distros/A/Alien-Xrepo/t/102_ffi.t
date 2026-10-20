use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Require::AuthorTesting;
use Path::Tiny qw[path];
use File::Temp qw[tempdir];
use Alien::Xrepo;
no warnings qw[experimental::builtin];
$|++;
#
my $lib_path;
#
try {
    #~ my $TODO = todo 'zlib might not build';
    my $tmp  = path( tempdir() );
    my $repo = Alien::Xrepo->new( root => $tmp, verbose => 0, kind => 'shared' );
    my $zlib = $repo->install('zlib');
    ok defined $zlib, 'Installed zlib';
    $lib_path = $zlib->libpath;
    diag 'zlib libpath: ' . ( $lib_path // '(none)' );
}
catch ($e) { skip_all 'zlib has no usable shared library for FFI wrapping' }
#
subtest Affix => sub {
    skip_all 'Affix is not installed' unless builtin::load_module 'Affix';
    Affix::affix( $lib_path, [ zlibVersion => 'a_zlibVersion' ], [] => Affix::String() );
    my $v = a_zlibVersion();
    ok defined $v && length $v, 'Affix bound and called zlibVersion: ' . ( $v // '(undef)' );
    like $v, qr[^\d+\.\d+\.\d+], 'zlibVersion returned a semver-ish string';
};
subtest Platypus => sub {
    skip_all 'FFI::Platypus is not installed' unless builtin::load_module 'FFI::Platypus';
    my $plat = FFI::Platypus->new( api => 2 );
    $plat->lib($lib_path);
    $plat->attach( [ zlibVersion => 'p_zlibVersion' ] => [] => 'string' );
    my $v = p_zlibVersion();
    ok defined $v && length $v, 'Platypus bound and called zlibVersion: ' . ( $v // '(undef)' );
    like $v, qr[^\d+\.\d+\.\d+], 'zlibVersion returned a semver-ish string';
};
#
done_testing;
